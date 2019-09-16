from Harvester import *
from bs4 import BeautifulSoup
from crawler.SiteMapCrawler import SiteMapCrawler
import json, numbers
from xml.dom.minidom import Document
import hashlib
from utils.Request import Request as myRequest
from rdflib import Graph
from rdflib.plugin import register, Serializer
register('json-ld', Serializer, 'rdflib_jsonld.serializer', 'JsonLDSerializer')
import asyncio
from aiohttp import ClientSession, TCPConnector, ClientTimeout, client_exceptions, http_exceptions
from timeit import default_timer

class JSONLDHarvester(Harvester):
    """
       {
            "id": "JSONLDHarvester",
            "title": "JSONLD Harvester",
            "description": "JSONLD Harvester to fetch JSONLD metadata using a site map (xml or text)",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    urlLinksList = {}
    combineFiles = False
    batchSize = 400
    tcp_connection_limit = 20
    async_list = []
    jsonDict = []
    batchCount = 0
    start_time = {}

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        try:
            if self.harvestInfo['requestHandler'] :
                pass
        except KeyError:
            self.harvestInfo['requestHandler'] = 'asyncio'
        if myconfig.tcp_connection_limit is not None and isinstance(myconfig.tcp_connection_limit, int):
            self.tcp_connection_limit = myconfig.tcp_connection_limit
            # generic in-house xslt to convert json-ld (xml) to rifcs
        if self.harvestInfo['xsl_file'] == "":
            self.harvestInfo['xsl_file'] = myconfig.run_dir + "resources/schemadotorg2rif.xsl"


    def harvest(self):
        self.stopped = False
        self.setupdirs()
        self.setUpCrosswalk()
        self.updateHarvestRequest()
        self.logger.logMessage("JSONLDHarvester Started")
        self.recordCount = 0
        self.getPageList()
        if len(self.urlLinksList) > self.batchSize:
            self.combineFiles = True
        self.crawlPages()
        if self.combineFiles is True:
            self.storeJsonData(self.jsonDict, 'combined_end')
            self.storeDataAsRDF(self.jsonDict, 'combined_end')
            self.storeDataAsXML(self.jsonDict, 'combined_end')
        self.setStatus("Generated %s File(s)" % str(self.recordCount))
        self.logger.logMessage("Generated %s File(s)" % str(self.recordCount))
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getPageList(self):
        self.setStatus("Scanning Sitemap(s)")
        sc = SiteMapCrawler(self.harvestInfo)
        sc.parse_sitemap()
        self.urlLinksList = sc.getLinksToCrawl()
        self.listSize = len(self.urlLinksList)
        self.setStatus("Scanning %d Pages" %len(self.urlLinksList))
        self.logger.logMessage("%s Pages found" %str(len(self.urlLinksList)))


    def setCombineFiles(self, tf):
        self.combineFiles = tf

    def crawlPages(self):
        self.start_time['start'] = default_timer()

        if self.harvestInfo['requestHandler'] == 'asyncio':
            asyncio.set_event_loop(asyncio.new_event_loop())
            loop = asyncio.get_event_loop()  # event loop
            future = asyncio.ensure_future(self.fetch_all())  # tasks to do
            loop.run_until_complete(future)  # loop until done
        else:
            for url in self.urlLinksList:
                r = myRequest(url)
                data = r.getData()
                self.processContent(data, url)

        tot_elapsed = default_timer() - self.start_time['start']
        self.logger.logMessage("Using %s ran %.2f seconds" %(self.harvestInfo['requestHandler'] , tot_elapsed))


    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" %(str(request.url), str(exception)), "ERROR")

    async def fetch_all(self):
        tasks = []
        minute = 60
        sessionTimeout = myconfig.max_up_seconds_per_harvest - minute
        cTimeout = ClientTimeout(total=sessionTimeout, connect=minute)
        connector = TCPConnector(limit=self.tcp_connection_limit, ssl=False)
        async with ClientSession(connector=connector, timeout=cTimeout) as session:
            for url in self.urlLinksList:
                task = asyncio.ensure_future(self.fetch(url, session))
                tasks.append(task)  # create list of tasks
            _ = await asyncio.gather(*tasks)  # gather task responses

    async def fetch(self, url, session):
        try:
            async with session.get(url) as response:
                resp = await response.read()
                self.processContent(resp.decode('utf-8'), url)
        except Exception as exc:
            self.logger.logMessage("Request Failed for %s Exception: %s" % (str(url), str(exc)), "ERROR")



    def processContent(self, htmlStr, url):
        html_soup = BeautifulSoup(htmlStr, 'html.parser')
        jsonlds = html_soup.find_all("script", attrs={'type':'application/ld+json'})
        jsonld = None
        if len(jsonlds) > 0:
            jsonld = jsonlds[0].text
        if jsonld is not None:
            try:
                data = json.loads(jsonld, strict=False)
                self.setStatus("Scanning %d Pages" % len(self.urlLinksList), "Processed %d:" % (self.recordCount))
                if self.combineFiles is True:
                    self.jsonDict.append(data)
                    time.sleep(0.1)
                    if len(self.jsonDict) >= self.batchSize:
                        self.saveBatch()
                else:
                    fileName = getFileName(data)
                    message = "HARVESTING %s" % fileName
                    self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest',
                                                message)
                    self.storeJsonData(data, fileName)
                    self.storeDataAsRDF(jsonld, fileName)
                    self.storeDataAsXML(data, fileName)
                self.recordCount += 1
            except Exception as e:
                self.logger.logMessage("URL : %s, ERROR: %s, JSONLD %s" %(url, str(e), jsonld), "ERROR")
        else:
            self.logger.logMessage("Unable to extract jsonld from page %s" % url, "DEBUG")


    def saveBatch(self):
            try:
                self.batchCount += 1
                self.logger.logMessage("JSONLDHarvester (saveBatch) %d ,%d" % (len(self.jsonDict), self.batchCount), "DEBUG")
                self.setStatus("Scanning %d Pages" % len(self.urlLinksList), "saving batch %d:" % (self.batchCount))
                chunkDict = self.jsonDict.copy()
                self.jsonDict.clear()
                self.storeJsonData(chunkDict, 'combined_%d' %self.batchCount)
                self.storeDataAsRDF(chunkDict, 'combined_%d' %self.batchCount)
                self.storeDataAsXML(chunkDict, 'combined_%d' %self.batchCount)
            except Exception as e:
                print(e)


    def storeJsonData(self, data, fileName):
        if self.stopped:
           return
        outputFilePath = self.outputDir + os.sep + fileName + ".json"
        dataFile = open(outputFilePath, 'w')
        try:
            json.dump(data, dataFile)
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("JSONLDHarvester (storeJsonData) %s " % (str(repr(e))), "ERROR")
        dataFile.close()
        os.chmod(outputFilePath, 0o775)


    def storeDataAsRDF(self, jsonld, fileName):
        outputFilePath = self.outputDir + os.sep + fileName + ".rdf"
        dataFile = open(outputFilePath, 'w')
        g = Graph()
        try:
            if(isinstance(jsonld, list)):
                for j in jsonld:
                    g.parse(data=json.dumps(j), format='application/ld+json')
            elif(isinstance(jsonld, str)):
                g = Graph().parse(data=jsonld, format='application/ld+json')
            g.serialize(outputFilePath, "xml")
        except Exception as e:
            self.logger.logMessage("JSONLDHarvester (storeDataAsRDF) %s " % (str(repr(e))), "ERROR")
        dataFile.close()
        os.chmod(outputFilePath, 0o775)

    def storeDataAsXML(self, data, fileName):
        self.__xml = Document()
        outputFilePath = self.outputDir + os.sep + fileName + "." + self.storeFileExtension
        dataFile = open(outputFilePath, 'w')
        try:
            if self.stopped:
                return
            elif isinstance(data, list):
                root = self.__xml.createElement('datasets')
                self.__xml.appendChild(root)
                for j in data:
                    ds = self.__xml.createElement('dataset')
                    self.parse_element(ds, j)
                    root.appendChild(ds)
                self.__xml.writexml(dataFile)
            else:
                root = self.__xml.createElement('dataset')
                self.__xml.appendChild(root)
                self.parse_element(root, data)
                self.__xml.writexml(dataFile)
        except Exception as e:
            self.logger.logMessage("JSONLDHarvester (storeDataAsXML) %s " % (str(repr(e))), "ERROR")

        dataFile.close()
        os.chmod(outputFilePath, 0o775)


    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        self.logger.logMessage("runCrossWalk XSLT: %s" % self.harvestInfo['xsl_file'])
        self.logger.logMessage("OutDir: %s" % self.outputDir)
        for file in os.listdir(self.outputDir):
            if file.endswith(self.storeFileExtension):
                self.logger.logMessage("runCrossWalk %s" %file)
                outFile = self.outputDir + os.sep + file.replace(self.storeFileExtension, self.resultFileExtension)
                inFile = self.outputDir + os.sep + file
                try:
                    transformerConfig = {'xsl': self.harvestInfo['xsl_file'], 'outFile': outFile, 'inFile': inFile}
                    tr = XSLT2Transformer(transformerConfig)
                    tr.transform()
                except subprocess.CalledProcessError as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()), "ERROR")
                    msg = "'ERROR WHILE RUNNING CROSSWALK %s '" %(e.output.decode())
                    self.handleExceptions(msg)
                except Exception as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s" %(e), "ERROR")
                    self.handleExceptions(e)


    def parse_element(self, root, j):
        if j is None:
            return
        if isinstance(j, dict):
            for key in j.keys():
                value = j[key]
                if isinstance(value, list):
                    for e in value:
                        elem = self.getElement(key)
                        self.parse_element(elem, e)
                        root.appendChild(elem)
                else:
                    if key.isdigit():
                        elem = self.__xml.createElement('item')
                        elem.setAttribute('value', key)
                    else:
                        elem = self.getElement(key)
                    self.parse_element(elem, value)
                    root.appendChild(elem)
        elif isinstance(j, str):
            text = self.__xml.createTextNode(j.encode('ascii', 'xmlcharrefreplace').decode('utf-8').encode('unicode-escape').decode('utf-8'))
            root.appendChild(text)
        elif isinstance(j, numbers.Number):
            text = self.__xml.createTextNode(str(j))
            root.appendChild(text)
        else:
            raise Exception("bad type %s for %s" % (type(j), j,))


    def getElement(self, jsonld_key):
        qName = jsonld_key.replace(' ', '')
        qName = qName.replace('@', '')
        ns = qName.split("#", 2)
        if len(ns) == 2:
            elem = self.__xml.createElement(ns[1])
        else:
            elem = self.__xml.createElement(qName)
        return elem


def asterisks(num):
    """Returns a string of asterisks reflecting the magnitude of a number."""
    return int(num*10)*'*'

def getFileName(data):
    id = "NOTHING"
    try:
        id = data['url']
    except KeyError:
        try:
            id = data['@id']
        except KeyError:
            id = datetime.now().strftime("%Y-%m-%d")
    h = hashlib.md5()
    h.update(id.encode())

    return h.hexdigest()