import urllib
from Harvester import *
from bs4 import BeautifulSoup
from bs4.diagnose import diagnose
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
class ARCAsyncHarvester(Harvester):
    """
       {
            "id": "ARCAsyncHarvester",
            "title": "ARC async Harvester",
            "description": "ARC Harvester to fetch grant metadata",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    # the number of pages stored per batchfile
    batchSize = 400

    # the number of simultaneous connections
    tcp_connection_limit = 5

    # the array to store the harvested grant json
    jsonDict = []

    # use to benchmark asyncio vs grequest vs request
    start_time = {}

    # request header; some servers refuse to respond unless User-Agent is given
    headers = {'User-Agent': 'ARDC Harvester'}

    # the number of records received in the current request
    numberOfRecordsReturned = 1

    #Only used in development testing
    testList = []

    # the list of grant_ids the harvester received
    __grantsList = []

    # the number of pages the harvester received
    pageCount = 0
    pageCall = 1

    # the number of grants in initial call to scrape grant_ids
    rows = 1000

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.jsonDict = []
        self.data = None
        self.__grantsList = []
        try:
            if self.harvestInfo['requestHandler'] :
                pass
        except KeyError:
            self.harvestInfo['requestHandler'] = 'grequests'
        if myconfig.tcp_connection_limit is not None and isinstance(myconfig.tcp_connection_limit, int):
            self.tcp_connection_limit = myconfig.tcp_connection_limit
            # generic in-house xslt to convert json-ld (xml) to rifcs
        if self.harvestInfo['xsl_file'] == "":
            self.harvestInfo['xsl_file'] = myconfig.run_dir + "resources/ARCAPI_json_to_rif-cs.xsl"


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
        self.logger.logMessage("ARCSyncHarvester Started")
        self.recordCount = 0
        while not self.errored and not self.completed and not self.stopped \
                and self.numberOfRecordsReturned > 0:
            self.getGrantsList()
        batchCount = 1
        self.stopped = False
        if len(self.__grantsList) > self.batchSize:
            grantLists = split(self.__grantsList, self.batchSize)
            for batches in grantLists:
                self.getGrants(batches)
                if len(self.jsonDict) > 0:
                    self.storeJsonData(self.jsonDict, 'combined_%d' %(batchCount))
                    self.storeDataAsXML(self.jsonDict, 'combined_%d' %(batchCount))
                    self.logger.logMessage("Saving %d records in combined_%d" % (len(self.jsonDict), batchCount))
                    self.jsonDict.clear()
                    batchCount += 1
                time.sleep(2) # let them breathe
        else:
            self.getGrants(self.__grantsList)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict, 'combined')
                self.storeDataAsXML(self.jsonDict, 'combined')
                self.setStatus("Generated %s File(s)" % str(self.recordCount))
                self.logger.logMessage("Generated %s File(s)" % str(self.recordCount))
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getGrantsList(self):
        """
        Using the arc grants portal  query we can obtain the identifiers all items the dataportal server provides
        :return:
        :rtype:
        """
        if self.stopped:
            return
        # while not self.errored and not self.completed and not self.stopped:
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)
        self.logger.logMessage("getGrantsList uri %s " % (request_url) )
        self.setStatus("HARVESTING")
        # we will collect grantids from the output page by page for later processing
        try:
            self.logger.logMessage("getGrantsList getting data")
            self.data = getRequest.getData()
            self.logger.logMessage("got data")
            self.pageCall += 1
            self.pageCount += 1
            package = json.loads(self.data);
            self.getRecordCount()
            if isinstance(package, dict):
                i = 0
                while i < len(package['data']):
                    self.__grantsList.append(package['data'][i]['id'])
                    i += 1
                # check if the collection of ids is completed by receiving nothing or more than the test limit
                if self.numberOfRecordsReturned == 0 or (
                        self.harvestInfo['mode'] == 'TEST' and self.recordCount >= myconfig.test_limit):
                    self.stopped = True
        except Exception as e:
            self.handleExceptions(e)
            self.errored = True
            self.__grantsList.append(e)
            return(e)
            return
        del getRequest
        return(self.__grantsList)

    def getRequestUrl(self):
        """
        append the start and limit to the end of the query
        :return url:
        """
        urlParams = {}
        urlParams['page[number]'] = str(self.pageCall)
        urlParams['page[size]'] = self.rows

        query = urllib.parse.urlencode(urlParams)

        return self.harvestInfo['uri'] + "?" + query

    def getRecordCount(self):
        """
        checks if the request is successful and determines the record count we received and increments the total count
        :return:
        """

        self.numberOfRecordsReturned = 0
        if self.stopped:
            return
        try:
            data = json.loads(self.data, strict=False)
            self.totalCount = int(data['meta']['total-size'])

            if self.totalCount > 0:
                self.numberOfRecordsReturned = int(data['meta']['actual-page-size'])

            self.logger.logMessage("ARC Harvester (numberOfRecordsReturned) %d of %d" % ((self.numberOfRecordsReturned * self.pageCount), self.totalCount), "DEBUG")
            # sanity check
            self.recordCount += self.numberOfRecordsReturned
            if self.recordCount >= self.totalCount:
                self.logger.logMessage(" ARC Harvester (Harvest Completed)", "DEBUG")
                self.completed = True
        except Exception:
            self.numberOfRecordsReturned = 0
            self.errored = True
            pass


    def getGrants(self, grantList):
        """
        depending on the implementation we can use either asyncio, grequest of simple request object to get the grant json
        found that grequest was somewhat best so set it as default
        :param urlList:
        :type urlList:
        """
        self.start_time['start'] = default_timer()

        if self.harvestInfo['requestHandler'] == 'asyncio':
            # the standard way to run asynchronous requests using asyncio
            asyncio.set_event_loop(asyncio.new_event_loop())
            loop = asyncio.get_event_loop()  # event loop
            future = asyncio.ensure_future(self.fetch_all(grantList))  # tasks to do
            loop.run_until_complete(future)  # loop until done
            loop.run_until_complete(asyncio.sleep(0.25))
            loop.run_until_complete(asyncio.sleep(0))
            loop.close()
        elif self.harvestInfo['requestHandler'] == 'grequests':
            # the standard way of implementing grequest using a map and action items
            async_list = []
            for grant in grantList:
                url = self.harvestInfo['uri'] + grant
                action_item = grequests.get(url, headers=self.headers, timeout=5, allow_redirects=True, hooks={'response': self.parse})
                async_list.append(action_item)
            grequests.map(async_list, size=self.tcp_connection_limit)
            asyncio.sleep(0.25)
            asyncio.sleep(0)
        else:
            for grant in grantList:
                url = self.harvestInfo['uri'] + grant
                r = myRequest(url)
                data = r.getData()
                self.jsonDict.append(data)

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
        if response.status_code < 400:
            self.jsonDict.append(response.text)
            self.recordCount += 1

    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" % (str(request.url), str(exception)), "ERROR")

    async def fetch_all(self, grantList):
        """
        fetch all using asyncio to handle request
        :param grantList:
        :type grantList:
        """
        tasks = []
        minute = 60

        sessionTimeout = myconfig.max_up_seconds_per_harvest - minute
        cTimeout = ClientTimeout(total=sessionTimeout)
        connector = TCPConnector(limit=self.batchSize, limit_per_host=self.tcp_connection_limit, force_close=True, ssl=False, enable_cleanup_closed=True)
        jar = DummyCookieJar()
        async with ClientSession(headers=self.headers, cookie_jar=jar,connector=connector, timeout=cTimeout, connector_owner=False) as session:
            for grant in grantList:
                url = self.harvestInfo['uri'] + grant
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
                self.jsonDict.append(resp.decode('utf-8'))
                response.close()
                await session.close()
        except Exception as exc:
            self.logger.logMessage("Request Failed for %s Exception: %s" % (str(url), str(exc)), "ERROR")



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
        self.logger.logMessage("ARCSyncHarvester (storeJsonData) %s " % (outputFilePath))
        dataFile = open(outputFilePath, 'w')
        try:
            json.dump(data, dataFile)
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("ARCSyncHarvester (storeJsonData) %s " % (str(repr(e))), "ERROR")
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
        self.logger.logMessage("ARCSyncHarvester (storeDataAsXML) for %s grants" % (len(data)))
        dataFile = open(outputFilePath, 'w')
        try:
            if self.stopped:
                return
            elif isinstance(data, list):
                root = self.__xml.createElement('grants')
                self.__xml.appendChild(root)
                for grantJson in data:
                    grant = json.loads(grantJson)
                    if isinstance(grant['links']['self'], str):
                        egrant = self.__xml.createElement('grant')
                        egrant.setAttribute('uri', grant['links']['self'])
                        self.parse_element(egrant, grant['data'])
                        root.appendChild(egrant)
                    else:
                        self.logger.logMessage("ARDCSyncHarvester (storeDataAsXML) %s " % (grant), 'ERROR')
                self.__xml.writexml(dataFile)
            else:
                grant = json.loads(data)
                if isinstance(grant['links']['self'], str):
                    root = self.__xml.createElement('grants')
                    egrant = self.__xml.createElement('grant')
                    egrant.setAttribute('uri', grant['links']['self'])
                    self.parse_element(egrant, grant['data'])
                    root.appendChild(egrant)
                else:
                    self.logger.logMessage("ARDCSyncHarvester data not a list (storeDataAsXML) ", 'ERROR')
                self.__xml.writexml(dataFile)
        except Exception as e:
            self.logger.logMessage("ARDCSyncDHarvester (storeDataAsXML) %s" % (str(repr(e))), "ERROR")
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

    def addItemtoTestList(self, item):
        self.testList.append(item)

    def printTestList(self):
        print(*self.testList, sep = "\n")

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
