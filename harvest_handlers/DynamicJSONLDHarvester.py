from Harvester import *
from selenium import webdriver
import time
import socket, http.client
#use webdriver from seleniumwire if you want to check for response code
#from seleniumwire import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException, TimeoutException
from concurrent import futures
from webdriver_manager.chrome import ChromeDriverManager
from crawler.SiteMapCrawler import SiteMapCrawler
import json
from xml.dom.minidom import Document
from rdflib import Graph
from rdflib.plugin import register, Serializer
register('json-ld', Serializer, 'rdflib_jsonld.serializer', 'JsonLDSerializer')
import ast
import urllib.parse as urlparse

class DynamicJSONLDHarvester(Harvester):
    """
       {
            "id": "DynamicJSONLDHarvester",
            "title": "Dynamically inserted JSONLD Harvester",
            "description": "JSONLD Harvester to fetch JSONLD metadata dynamically inserted . Uses a site map (xml or text)",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    # the list of urls the crawler has found
    urlLinksList = []
    # the list of urls that the webdriver failed to receive back json-ld from
    urlFailedRequest = []
    # the number of pages stored per batchfile
    batchSize = 500
    # the number of simultaneous connections
    tcp_connection_limit = 2
    # time in seconds to wait for application/ld_json script tag to load
    wait_page_load = 15
    # the array to store the harvested json-lds
    jsonDict = []
    # use to benchmark asyncio vs grequest vs request
    start_time = {}
    # use to create a pool of webdrivers
    driver_list = []
    re_run = None
    # request header; some servers refuse to respond unless User-Agent is given
    headers = {'User-Agent': 'ARDC Harvester'}
    # Chrome browser options for the webdriver - headless, no images and disk-cache size
    browser_options = Options()
    # chromedriver = myconfig.run_dir + "resources/chromedriver"
    browser_options.add_argument("--headless")
    browser_options.add_argument('--disable-setuid-sandbox')
    browser_options.add_argument('--no-sandbox')
    prefs = {'profile.managed_default_content_settings.images': 2}
    browser_options.add_experimental_option("prefs", prefs)
    start_time_dict = None
    end_time_dict = None


    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.jsonDict = []
        self.data = None
        self.urlLinksList = []
        self.re_run = False
        self.start_time_dict = dict()
        self.end_time_dict = dict()
        try:
            if self.harvestInfo['requestHandler'] :
                pass
        except KeyError:
            self.harvestInfo['requestHandler'] = 'asyncio'
        if self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == "":
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
        self.logger.logMessage("DynamicJSONLDHarvester Started")
        self.recordCount = 0
        self.getPageList()
        batchCount = 1
        self.logger.logMessage("Found %d urls in file, batching %d" % (len(self.urlLinksList) , self.batchSize))
        self.openDrivers()
        if len(self.urlLinksList) > self.batchSize:
            urlLinkLists = split(self.urlLinksList, self.batchSize)
            for batches in urlLinkLists:
                self.crawlPages(batches)
                if len(self.jsonDict) > 0:
                    self.storeJsonData(self.jsonDict, 'combined_%d' %(batchCount))
                    self.storeDataAsXML(self.jsonDict, 'combined_%d' %(batchCount))
                    self.logger.logMessage("Saving %d records in combined_%d" % (len(self.jsonDict), batchCount))
                    self.jsonDict.clear()
                    batchCount += 1
                time.sleep(2)  # let them breathe
        else:
            self.crawlPages(self.urlLinksList)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict, 'combined')
                self.storeDataAsXML(self.jsonDict, 'combined')
                self.logger.logMessage("Saving %d records in combined" % len(self.jsonDict))
                self.jsonDict.clear()
        if(len(self.urlFailedRequest)>0):
            self.re_run = True
            self.logger.logMessage("Trying to reload %d pages" % len(self.urlFailedRequest))
            #double the wait time, feel generous
            self.wait_page_load = 60  # increase wait time to 60 seconds
            self.crawlPages(self.urlFailedRequest)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict,  'combined_%d' %(batchCount))
                self.storeDataAsXML(self.jsonDict,  'combined_%d' %(batchCount))
                self.logger.logMessage("Saving %d records in combined_%d" % (len(self.jsonDict), batchCount))
                self.jsonDict.clear()
        self.closeDrivers()
        self.setStatus("Generated %s File(s)" % str(self.recordCount))
        self.logger.logMessage("Generated %s File(s)" % str(self.recordCount))
        self.runCrossWalk()
        self.logStats()
        self.postHarvestData()
        self.finishHarvest()

    def logStats(self):
        for url, start_time in self.start_time_dict.items():
            try:
                end_time = self.end_time_dict[url]
                overall = end_time - start_time
                self.logger.logMessage("URL: %s took %s seconds" % (url, str(overall)), 'INFO')
            except KeyError:
                self.logger.logMessage("URL: %s failed to load" % url, 'INFO')



    def getPageList(self):
        """
        use the SitemapCrawler to get all urls for a given site
        add all urls to the urlLinksList
        """

        self.logger.logMessage("getting the urls")
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
        create threads for calls to urls to obtain the json+ld

        :param urlList:
        :type array:
        :param driver:
        :type webdriver:
        """

        with futures.ThreadPoolExecutor(max_workers=self.tcp_connection_limit) as executor:
            executor.map(self.fetch, urlList)
            executor.shutdown(wait=True)

    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" % (str(request.url), str(exception)), "ERROR")



    def openDrivers(self):
        """
          creates a pool of webdrivers and sets them to abailable
        """
        for i in range(0, self.tcp_connection_limit):
            theDriver =   webdriver.Chrome(ChromeDriverManager().install(), options=self.browser_options)
            self.driver_list.append([theDriver, 0])

    def closeDrivers(self):
        """
        closes the pool of webdrivers
        """
        for i in range(0, self.tcp_connection_limit):
            driver = self.driver_list[i][0]
            thePid = driver.service.process.pid
            try:
                driver.quit()
            except http.client.CannotSendRequest:
                self.logger.logMessage( "Driver did not terminate")
            except socket.error:
                self.logger.logMessage("Socket did not terminate")
            else:
                self.logger.logMessage("Quiting driver  %s with pid %s " % (str(driver), str(thePid)), "DEBUG")

        self.driver_list = []


    def getDriver(self):
        """
        get an available webdriver
        """

        for driverInfo in self.driver_list:
            try:
                if (driverInfo[1] == 0):
                    driver = driverInfo[0]
                    driverInfo[1] = 1
                    return driver
                    break
            except Exception as exc:
                self.logger.logMessage("Failed assigning driver %s Exception: %s" % (str(driver), str(exc)), "ERROR")

    def returnDriver(self, driver):
        """
        free the webdriver
        """

        for driverInfo in self.driver_list:
            try:
                if (driverInfo[0] == driver):
                    driverInfo[1] = 0
                    break
            except Exception as exc:
                self.logger.logMessage("Failed freeing driver%s Exception: %s" % (str(driver) , str(exc)), "ERROR")


    def fetch(self, url):
        """
        the fetch method for asyncio requests
        pass the response to the generic content handler: processContent
        :param url:
        :type url:
        :param driver:
        :type webdriver:
        """
        time.sleep(.25)  # let them breathe a bit
        driver = self.getDriver()    
        try:
            # capture the time it takes to load urls that failed under the initial wait time
            if self.re_run:
                self.start_time_dict[url] = time.time()
            driver.get(url)
            self.logger.logMessage("Fetching url : %s" % url, "DEBUG")
            WebDriverWait(driver, self.wait_page_load).until(
                EC.presence_of_element_located((By.XPATH,'//script[@type="application/ld+json"]')))
            if self.re_run:
                self.end_time_dict[url] = time.time()
            final_results = driver.find_element_by_xpath('//script[@type="application/ld+json"]')
            the_json = final_results.get_attribute("innerHTML")
            self.processContent(str(the_json), url)
        except TimeoutException as tEx:
            self.logger.logMessage("TimeoutException: url: %s, wait_time:%s" % (url, str(self.wait_page_load)), "ERROR")
            if not self.re_run:
                self.urlFailedRequest.append(url)
        except NoSuchElementException as nExc:
            self.logger.logMessage("Page contains no json-ld, url: %s, exc: %s" % (url, repr(nExc)), "ERROR")
        self.returnDriver(driver)

    def processContent(self, jsonStr, url):
        """
        the json-ld content extractor all request pass their data to this content handler
        it will attempt to parse the jsonStr string into a json object
        if successful it adds the json-ld into an list (to be processed once all page in the current batch is extracted
        or no more pages left)
        :param jsonStr:
        :type str:
        :param url:
        :type url:

        """
        if jsonStr is not None and jsonStr != '':
            message = "%d-%d, url: %s" % (self.recordCount, len(self.urlLinksList), url)
            try:
                data = {}
                try:
                    data = json.loads(jsonStr, strict=False)
                    if not 'url' in data:
                        data['url'] = url
                except Exception as e:
                    data = ast.literal_eval(jsonStr)
                self.setStatus("Scanning %d Pages" % len(self.urlLinksList), message)
                self.jsonDict.append(data)
                self.recordCount += 1
            except Exception as e:
                pass
        else:
            self.logger.logMessage("processContent url:%s CONTENT: %s" % (url, jsonStr))


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
