from Harvester import *
from bs4 import BeautifulSoup
from crawler.SiteMapCrawler import SiteMapCrawler
import json
from xml.dom.minidom import Document
from utils.Request import Request as myRequest
from rdflib import Graph
from rdflib.plugin import register, Serializer
register('json-ld', Serializer, 'rdflib_jsonld.serializer', 'JsonLDSerializer')
import asyncio
from aiohttp import ClientSession, TCPConnector, ClientTimeout, DummyCookieJar, http_exceptions
from timeit import default_timer
import ast
import grequests
import urllib.parse as urlparse
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
    # the list of urls the crawler has found
    urlLinksList = []
    # the number of pages stored per batchfile
    batchSize = 400
    # the number of simultaneous connections
    tcp_connection_limit = 5
    # the array to store the harvested json-lds
    jsonDict = []
    # use to benchmark asyncio vs grequest vs request
    start_time = {}
    # request header; some servers refuse to respond unless User-Agent is given
    headers = {'User-Agent': 'ARDC Harvester'}

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.jsonDict = []
        self.data = None
        self.urlLinksList = []
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
        """
        the harvest method
        the usual set of procedures
        except we need to get a list of pages to extract the json-ld from
        get all content (in batches)
        save all content (in batches)
        run crosswalk after all content is received
        tell the registry the harvest is completed
        finish harvest
        """
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
                    #self.storeDataAsRDF(self.jsonDict, 'combined_%d' %(batchCount))
                    self.storeDataAsXML(self.jsonDict, 'combined_%d' %(batchCount))
                    self.logger.logMessage("Saving %d records in combined_%d" % (len(self.jsonDict), batchCount))
                    self.jsonDict.clear()
                    batchCount += 1
                time.sleep(2) # let them breathe
        else:
            self.crawlPages(self.urlLinksList)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict, 'combined')
                #self.storeDataAsRDF(self.jsonDict, 'combined')
                self.storeDataAsXML(self.jsonDict, 'combined')
        self.setStatus("Generated %s File(s)" % str(self.recordCount))
        self.logger.logMessage("Generated %s File(s)" % str(self.recordCount))
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()


    def getPageList(self):
        """
        use the SitemapCrawler to get all urls for a given site
        add all urls to the urlLinksList
        """
        try:
            self.setStatus("Scanning Sitemap(s)")
            sc = SiteMapCrawler(self.harvestInfo['mode'])
            sc.parse_sitemap(self.harvestInfo['uri'])
            self.urlLinksList = sc.getLinksToCrawl()
            self.listSize = len(self.urlLinksList)
            self.setStatus("Scanning %d Pages" %len(self.urlLinksList))
            self.logger.logMessage("%s Pages found" %str(len(self.urlLinksList)), 'INFO')
        except Exception as e:
            self.logger.logMessage(str(repr(e)), "ERROR")
            self.handleExceptions(e, terminate=True)


    def crawlPages(self, urlList):
        """
        depending on the implementation we can use either asyncio, grequest of simple request object to crawl the pages
        fund that grequest was somewhat best so set it as default
        :param urlList:
        :type urlList:
        """
        self.start_time['start'] = default_timer()

        if self.harvestInfo['requestHandler'] == 'asyncio':
            # the standard way to run asynchronous requests using asyncio
            asyncio.set_event_loop(asyncio.new_event_loop())
            loop = asyncio.get_event_loop()  # event loop
            future = asyncio.ensure_future(self.fetch_all(urlList))  # tasks to do
            loop.run_until_complete(future)  # loop until done
            loop.run_until_complete(asyncio.sleep(0.25))
            loop.run_until_complete(asyncio.sleep(0))
            loop.close()
        elif self.harvestInfo['requestHandler'] == 'grequests':
            # the standard way of implementing grequest using a map and action items
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
        self.logger.logMessage("Using %s ran %.2f seconds" %(self.harvestInfo['requestHandler'], tot_elapsed))


    def parse(self, response, **kwargs):
        """
        grequest parse callback
        just get the content and call the generic content handler processContent
        :param response:
        :type response:
        :param kwargs:
        :type kwargs:
        """
        self.processContent(response.text, response.url)

    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" % (str(request.url), str(exception)), "ERROR")

    async def fetch_all(self, urlList):
        """
        fetch all using asyncio to handle request
        :param urlList:
        :type urlList:
        """
        tasks = []
        minute = 60

        sessionTimeout = myconfig.max_up_seconds_per_harvest - minute
        cTimeout = ClientTimeout(total=sessionTimeout)
        connector = TCPConnector(limit=self.batchSize, limit_per_host=self.tcp_connection_limit, force_close=True, ssl=False, enable_cleanup_closed=True)
        jar = DummyCookieJar()
        async with ClientSession(headers=self.headers, cookie_jar=jar,connector=connector, timeout=cTimeout, connector_owner=False) as session:
            for url in urlList:
                task = asyncio.ensure_future(self.fetch(url, session))
                tasks.append(task)  # create list of tasks
            _ = await asyncio.gather(*tasks)  # gather task responses


    async def fetch(self, url, session):
        """
        the fetch method for asyncio requests
        pass the response to the generic content handler: processContent
        :param url:
        :type url:
        :param session:
        :type session:
        """
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
        """
        the json-ld content extractor all request pass their data to this content handler
        it tries to find a script tag with type application/ld+json
        if ther's any it will attempt to parse the first json-ld string into a json object
        if successful it adds the json-ld into an list (to be processed once all page in the current batch is extracted
        or no more pages left
        :param htmlStr:
        :type htmlStr:
        :param url:
        :type url:
        """
        self.logger.logMessage("processContent jsonlds[0].text url:%s CONTENT: %s" % (url, htmlStr))
        html_soup = BeautifulSoup(htmlStr, 'html.parser')
        jsonlds = html_soup.find_all("script", attrs={'type':'application/ld+json'})
        jsonld = None
        if len(jsonlds) > 0:
            jsonld = jsonlds[0].text
            self.logger.logMessage("processContent jsonlds[0].text %s" %jsonlds[0].text)
        if jsonld is not None:
            message = "%d-%d, url: %s" % (self.recordCount, len(self.urlLinksList), url)
            try:
                data = {}
                try:
                    data = json.loads(jsonld, strict=False)

                    if not 'url' in data:
                        data['url'] = url
                except Exception as e:
                    data = ast.literal_eval(jsonld)
                self.logger.logMessage("processContent data %s" %str(data))
                self.setStatus("Scanning %d Pages" % len(self.urlLinksList), message)
                self.jsonDict.append(data)
                self.recordCount += 1
            except Exception as e:
                pass
        else:
            self.logger.logMessage("processContent url:%s CONTENT: %s" % (url, htmlStr))


    def storeJsonData(self, data, fileName):
        """
        stores a batch of json objects in a json file
        :param data:
        :type data:
        :param fileName:
        :type fileName:
        :return:
        :rtype:
        """
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
        """
        creates a graph of a bacth of json-ld objects and serialise it as RDF file
        not used but are considering
        :param jsonld:
        :type jsonld:
        :param fileName:
        :type fileName:
        """
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
        """
        serialise the json-ld objects as a set of XML elements (needed for XSLT to rif-cs)
        until XSLT can natively transform json
        :param data:
        :type data:
        :param fileName:
        :type fileName:
        :return:
        :rtype:
        """
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
        """
        scan through the result contents and run an xslt transfor
        generic in-house xslt to convert json-ld (xml) to rifcs unless the datasource harvest config sets an other XSLT
        :return:
        :rtype:
        """
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
                    parsed_url = urlparse.urlparse(self.harvestInfo['uri'])
                    transformerConfig = {'xsl': self.harvestInfo['xsl_file'], 'outFile': outFile,
                                         'inFile': inFile, 'originatingSource':"%s://%s" % (parsed_url.scheme, parsed_url.netloc),
                                         'group': self.harvestInfo['title']}

                    tr = XSLT2Transformer(transformerConfig)
                    tr.transform()
                except subprocess.CalledProcessError as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()), "ERROR")
                    msg = "'ERROR WHILE RUNNING CROSSWALK %s '" %(e.output.decode())
                    self.handleExceptions(msg)
                except Exception as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s" %(e), "ERROR")
                    self.handleExceptions(e)

    def setbatchSize(self, size):
        """
        only used in tests, not used in production
        :param size:
        :type size:
        """
        self.batchSize = size


    def getbatchSize(self):
        """
        only used in tests, not used in production
        :return:
        :rtype:
        """
        return self.batchSize


def split(arr, size):
    """
    sourced form https://stackoverflow.com/questions/752308/split-list-into-smaller-lists-split-in-half
    :param arr:
    :type arr:
    :param size:
    :type size:
    :return:
    :rtype:
    """
    arrs = []
    while len(arr) > size:
        pice = arr[:size]
        arrs.append(pice)
        arr = arr[size:]
    arrs.append(arr)
    return arrs
