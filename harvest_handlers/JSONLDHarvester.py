from Harvester import *
import grequests
from bs4 import BeautifulSoup
from crawler.SiteMapCrawler import SiteMapCrawler
import json, numbers
from xml.dom.minidom import Document
import hashlib
from utils.Request import Request as myRequest
from rdflib import Graph
from rdflib.plugin import register, Serializer
register('json-ld', Serializer, 'rdflib_jsonld.serializer', 'JsonLDSerializer')


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
    async_list = []
    jsonDict = []
    batchCount = 0

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
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
            self.storeJsonData(self.jsonDict, 'combined')
            self.storeDataAsRDF(self.jsonDict, 'combined')
            self.storeDataAsXML(self.jsonDict, 'combined')
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
        self.setStatus("Scanning %d Pages" %len(self.urlLinksList))
        self.logger.logMessage("%s Pages found" %str(len(self.urlLinksList)))


    def setCombineFiles(self, tf):
        self.combineFiles = tf

    def crawlPages(self):
        if self.harvestInfo['mode'] == 'TEST':
            for url in self.urlLinksList:
                r = myRequest(url)
                data = r.getData()
                self.parseHtmlStr(data)
        else:
            for url in self.urlLinksList:
                action_item = grequests.get(url, hooks={'response': self.parse})
                self.async_list.append(action_item)
            grequests.map(self.async_list, size=20)


    def exception_handler(self, request, exception):
        self.logger.logMessage("Request Failed for %s Exception: %s" %(str(request.url), str(exception)), "ERROR")


    def parseHtmlStr(self, htmlString):
        html_soup = BeautifulSoup(htmlString, 'html.parser')
        jsonlds = html_soup.find_all("script", attrs={'type':'application/ld+json'})
        jsonld = None
        if len(jsonlds) > 0:
            jsonld = jsonlds[0].text
        if jsonld is not None:
            #self.logger.logMessage("jsonlds: %s" % str(jsonld), "DEBUG")
            self.recordCount += 1
            data = json.loads(jsonld, strict=False)
            self.setStatus("Scanning %d Pages" % len(self.urlLinksList), "Processed %d:" % (self.recordCount))
            if self.combineFiles is True:
                self.jsonDict.append(data)
            else:
                fileName = getFileName(data)
                message = "HARVESTING %s" %fileName
                self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest', message)
                self.storeJsonData(data, fileName)
                self.storeDataAsRDF(jsonld, fileName)
                self.storeDataAsXML(data, fileName)
        else:
            self.logger.logMessage("No JSONLD found", "DEBUG")
        self.saveBatch()

    def parse(self, response, **kwargs):
        html_soup = BeautifulSoup(response.text, 'html.parser')
        jsonlds = html_soup.find_all("script", attrs={'type':'application/ld+json'})
        jsonld = None
        if len(jsonlds) > 0:
            jsonld = jsonlds[0].text
        if jsonld is not None:
            #self.logger.logMessage("jsonlds: %s" % str(jsonld), "DEBUG")
            self.recordCount += 1
            data = json.loads(jsonld, strict=False)
            if self.combineFiles is True:
                self.jsonDict.append(data)
            else:
                fileName = getFileName(data)
                message = "HARVESTING %s" %fileName
                self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest', message)
                self.storeJsonData(data, fileName)
                self.storeDataAsRDF(jsonld, fileName)
                self.storeDataAsXML(data, fileName)
        self.saveBatch()

    def saveBatch(self):
        if self.combineFiles is True and len(self.jsonDict) > self.batchSize:
            self.batchCount += 1
            self.setStatus("Scanning %d Pages" % len(self.urlLinksList), "saving batch %d:" % (self.batchCount))
            self.storeJsonData(self.jsonDict, 'combined_%d' %self.batchCount)
            self.storeDataAsRDF(self.jsonDict, 'combined_%d' %self.batchCount)
            self.storeDataAsXML(self.jsonDict, 'combined_%d' %self.batchCount)
            self.jsonDict.clear()

    def storeJsonData(self, data, fileName):
        if self.stopped:
           return
        try:
            outputFilePath = self.outputDir + os.sep + fileName + ".json"
            dataFile = open(outputFilePath, 'w')
            json.dump(data, dataFile)
            dataFile.close()
            os.chmod(outputFilePath, 0o775)
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("JSONLDHarvester (storeJsonData) %s " % (str(repr(e))), "ERROR")


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
            dataFile.close()
            os.chmod(outputFilePath, 0o775)
        except Exception as e:
            self.logger.logMessage("JSONLDHarvester (storeDataAsRDF) %s " % (str(repr(e))), "ERROR")

    def storeDataAsXML(self, data, fileName):
        self.__xml = Document()
        try:
            outputFilePath = self.outputDir + os.sep + fileName + "." + self.storeFileExtension
            dataFile = open(outputFilePath, 'w')

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
                dataFile.close()
            else:
                root = self.__xml.createElement('dataset')
                self.__xml.appendChild(root)
                self.parse_element(root, data)
                self.__xml.writexml(dataFile)
            dataFile.close()
            os.chmod(outputFilePath, 0o775)
        except Exception as e:
            self.logger.logMessage("JSONLDHarvester (storeDataAsXML) %s " % (str(repr(e))), "ERROR")


    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        self.logger.logMessage("runCrossWalk XSLT: %s" % self.harvestInfo['xsl_file'])
        self.logger.logMessage("OutDir: %s" % self.outputDir)
        for file in os.listdir(self.outputDir):
            self.logger.logMessage("Files: %s" % file)
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