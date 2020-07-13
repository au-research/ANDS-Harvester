from Harvester import *
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from concurrent import futures
from multiprocessing import Pool
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
    # the number of pages stored per batchfile
    batchSize = 400
    # the number of simultaneous connections
    tcp_connection_limit = 5
    # time to wait for application/ld_json script tag to load
    wait_page_load = 10
    # the array to store the harvested json-lds
    jsonDict = []
    # use to benchmark asyncio vs grequest vs request
    start_time = {}
    # request header; some servers refuse to respond unless User-Agent is given
    headers = {'User-Agent': 'ARDC Harvester'}
    # Chrome browser options for the webdriver - headless, no images and disk-cache size
    browser_options = Options()
    browser_options.add_argument("--headless")
    prefs = {'profile.managed_default_content_settings.images': 2,  'disk-cache-size': 4096 }
    browser_options.add_experimental_option("prefs", prefs)

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.jsonDict = []
        self.data = None
        self.urlLinksList = []

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
                #time.sleep(2) # let them breathe
        else:
            self.crawlPages(self.urlLinksList)
            if len(self.jsonDict) > 0:
                self.storeJsonData(self.jsonDict, 'combined')
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

        #pool = Pool(processes=self.test_tcp_connection_limit)
        #pool.map(self.fetch, urlList)
        with futures.ThreadPoolExecutor(max_workers=self.tcp_connection_limit) as executor:
            executor.map(self.fetch, urlList)


    #def parse(self, response, **kwargs):
    #    """
    #    grequest parse callback
    #    just get the content and call the generic content handler processContent
    #    :param response:
    #    :type response:
    #    :param kwargs:
    #   :type kwargs:
    #    """
        #self.processContent(response.text, response.url)

    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" % (str(request.url), str(exception)), "ERROR")


    def fetch(self, url):
        """
        the fetch method for asyncio requests
        pass the response to the generic content handler: processContent
        :param url:
        :type url:
        :param driver:
        :type webdriver:
        """
        driver = webdriver.Chrome(ChromeDriverManager().install(), options=self.browser_options)
        try:
            driver.get(url)
            WebDriverWait(driver, self.wait_page_load).until(
                EC.presence_of_element_located((By.XPATH,'//script[@type="application/ld+json"]')))
            final_results= driver.find_element_by_xpath('//script[@type="application/ld+json"]')
            the_json = final_results.get_attribute("innerHTML")
            self.processContent(str(the_json), url)
        except Exception as exc:
            # error may be due to open driver issue so lets try again with a whole new driver
            # A new driver results in a longer load time per page
            self.logger.logMessage("1st Request Failed for %s Exception: %s" % (str(url), str(exc)), "ERROR")
            try:
                driver2 = webdriver.Chrome(ChromeDriverManager().install(),options=self.browser_options)
                driver.get(url)
                WebDriverWait(driver2, 5).until(
                    EC.presence_of_element_located((By.XPATH, '//script[@type="application/ld+json"]')))
                final_results = driver2.find_element_by_xpath('//script[@type="application/ld+json"]')
                the_info = final_results.get_attribute("innerHTML")
                self.processContent(str(the_info), url)
                driver2.close()
                driver2.quit()
            except Exception as exc:
                self.logger.logMessage("2nd Request Failed for %s Exception: %s" % (str(url), str(exc)), "ERROR")
        driver.close()

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
        if jsonStr is not None:
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
                #self.logger.logMessage("processContent url:%s CONTENT: %s" % (url, jsonStr),'DEBUG')
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
