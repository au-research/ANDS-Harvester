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
from aiohttp import ClientSession, TCPConnector, ClientTimeout, DummyCookieJar, http_exceptions
from timeit import default_timer
import ast
import grequests

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
    batchSize = 400
    tcp_connection_limit = 5
    jsonDict = []
    start_time = {}
    headers = {'User-Agent': 'ARDC Harvester'}

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        try:
            if self.harvestInfo['requestHandler'] :
                pass
        except KeyError:
            self.harvestInfo['requestHandler'] = 'grequests'
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
        batchCount = 1
        if len(self.urlLinksList) > self.batchSize:
            urlLinkLists = split(self.urlLinksList, self.batchSize)
            for batches in urlLinkLists:
                self.crawlPages(batches)
                if len(self.jsonDict) > 0:
                    self.storeJsonData(self.jsonDict, 'combined_%d' %(batchCount))
                    self.storeDataAsRDF(self.jsonDict, 'combined_%d' %(batchCount))
                    self.storeDataAsXML(self.jsonDict, 'combined_%d' %(batchCount))
                    self.logger.logMessage("Saving %d records in combined_%d" % (len(self.jsonDict), batchCount))
                    self.jsonDict.clear()
                    batchCount += 1
                time.sleep(2) # let them breathe
        else:
            self.crawlPages(self.urlLinksList)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict, 'combined')
                self.storeDataAsRDF(self.jsonDict, 'combined')
                self.storeDataAsXML(self.jsonDict, 'combined')
        self.setStatus("Generated %s File(s)" % str(self.recordCount))
        self.logger.logMessage("Generated %s File(s)" % str(self.recordCount))
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getPageList(self):
        try:
            self.setStatus("Scanning Sitemap(s)")
            sc = SiteMapCrawler(self.harvestInfo)
            sc.parse_sitemap()
            self.urlLinksList = sc.getLinksToCrawl()
            self.listSize = len(self.urlLinksList)
            self.setStatus("Scanning %d Pages" %len(self.urlLinksList))
            self.logger.logMessage("%s Pages found" %str(len(self.urlLinksList)), 'INFO')
        except Exception as e:
            self.logger.logMessage(str(repr(e)), "ERROR")
            self.handleExceptions(e, terminate=True)

    def crawlPages(self, urlList):
        self.start_time['start'] = default_timer()

        if self.harvestInfo['requestHandler'] == 'asyncio':
            asyncio.set_event_loop(asyncio.new_event_loop())
            loop = asyncio.get_event_loop()  # event loop
            future = asyncio.ensure_future(self.fetch_all(urlList))  # tasks to do
            loop.run_until_complete(future)  # loop until done
            loop.run_until_complete(asyncio.sleep(0.25))
            loop.run_until_complete(asyncio.sleep(0))
            loop.close()
        elif self.harvestInfo['requestHandler'] == 'grequests':
            async_list = []
            for url in urlList:
                action_item = grequests.get(url, headers=self.headers, timeout=5, hooks={'response': self.parse})
                async_list.append(action_item)
            grequests.map(async_list, size=self.tcp_connection_limit)
            asyncio.sleep(0.25)
            asyncio.sleep(0)
        else:
            for url in urlList:
                r = myRequest(url)
                data = r.getData()
                self.processContent(data, url)

        tot_elapsed = default_timer() - self.start_time['start']
        self.logger.logMessage("Using %s ran %.2f seconds" %(self.harvestInfo['requestHandler'] , tot_elapsed))

    def parse(self, response, **kwargs):
        self.processContent(response.text, response.url)


    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" %(str(request.url), str(exception)), "ERROR")

    async def fetch_all(self, urlList):
        tasks = []
        minute = 60

        sessionTimeout = myconfig.max_up_seconds_per_harvest - minute
        cTimeout = ClientTimeout(total=sessionTimeout)
        connector = TCPConnector(limit=self.batchCount, limit_per_host=self.tcp_connection_limit, force_close=True, ssl=False, enable_cleanup_closed=True)
        jar = DummyCookieJar()
        async with ClientSession(headers=self.headers, cookie_jar=jar,connector=connector, timeout=cTimeout, connector_owner=False) as session:
            for url in urlList:
                task = asyncio.ensure_future(self.fetch(url, session))
                tasks.append(task)  # create list of tasks
            _ = await asyncio.gather(*tasks)  # gather task responses

    async def fetch(self, url, session):
        minute = 60
        cTimeout = ClientTimeout(connect=minute)
        try:
            async with session.get(url, ssl=False, timeout=cTimeout) as response:
                resp = await response.read()
                self.processContent(resp.decode('utf-8'), url)
                response.close()
                await session.close()
        except Exception as exc:
            self.logger.logMessage("Request Failed for %s Exception: %s" % (str(url), str(exc)), "ERROR")


    def processContent(self, htmlStr, url):
        html_soup = BeautifulSoup(htmlStr, 'html.parser')
        jsonlds = html_soup.find_all("script", attrs={'type':'application/ld+json'})
        jsonld = None
        if len(jsonlds) > 0:
            jsonld = jsonlds[0].text
        if jsonld is not None:
            message = "%d-%d, url: %s" % (self.recordCount, len(self.urlLinksList), url)
            #self.logger.logMessage(message, "DEBUG")
            try:
                data = {}
                try:
                    data = json.loads(jsonld, strict=False)
                except Exception as e:
                    data = ast.literal_eval(jsonld)
                self.setStatus("Scanning %d Pages" % len(self.urlLinksList), message)
                self.jsonDict.append(data)
                self.recordCount += 1
            except Exception as e:
                pass
                #self.logger.logMessage("URL : %s, ERROR: %s, JSONLD %s" %(url, str(e), jsonld), "ERROR")
        #else:
        #    self.logger.logMessage("Unable to extract jsonld from page %s" % url, "DEBUG")


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

#https://stackoverflow.com/questions/752308/split-list-into-smaller-lists-split-in-half

def split(arr, size):
    arrs = []
    while len(arr) > size:
        pice = arr[:size]
        arrs.append(pice)
        arr = arr[size:]
    arrs.append(arr)
    return arrs