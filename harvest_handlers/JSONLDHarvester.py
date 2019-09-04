from Harvester import *
import grequests
from bs4 import BeautifulSoup
from crawler.SiteMapCrawler import SiteMapCrawler
import json, numbers
from xml.dom.minidom import Document
import hashlib
from utils.Request import Request as myRequest


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
    __xml = None
    combineFiles = True
    async_list = []
    jsonDict = []

    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.outputDir = self.outputDir + os.sep + str(self.harvestInfo['batch_number'])
        if not os.path.exists(self.outputDir):
            os.makedirs(self.outputDir)
        if self.harvestInfo['xsl_file'] == "":
            self.harvestInfo['xsl_file'] = myconfig.run_dir + "resources/schemadotorg2rif.xsl"



    def harvest(self):
        self.cleanPreviousHarvestRecords()
        self.stopped = False
        self.logger.logMessage("JSONLDHarvester Started")
        self.recordCount = 0
        self.urlLinksList = {}
        self.getPageList()
        self.crawlPages()
        if self.combineFiles is True:
            self.storeJsonData(self.jsonDict, 'combined')
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
        self.setStatus("%s Pages found" %str(len(self.urlLinksList)))
        self.logger.logMessage("%s Pages found" %str(len(self.urlLinksList)))

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
        self.logger.logMessage("Request Failed for %s Exception: %s" % str(request.url), str(exception), "ERROR")


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
            if self.combineFiles is True:
                self.jsonDict.append(data)
            else:
                fileName = getFileName(data)
                message = "HARVESTING %s" %fileName
                self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest', message)
                self.storeJsonData(data, fileName)
                self.storeDataAsXML(data, fileName)
        else:
            self.logger.logMessage("No JSONLD found", "DEBUG")

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
                self.storeDataAsXML(data, fileName)

    def storeJsonData(self, data, fileName):
        if self.stopped:
           return
        try:
            outputFilePath = self.outputDir + os.sep + fileName + ".json"
            dataFile = open(outputFilePath, 'w', 0o777)
            json.dump(data, dataFile)
            dataFile.close()
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("JSONLDHarvester (storeJsonData) %s " % (str(repr(e))), "ERROR")



    def storeDataAsXML(self, data, fileName):
        try:
            self.__xml = Document()
            outputFilePath = self.outputDir + os.sep + fileName + "." + self.storeFileExtension
            dataFile = open(outputFilePath, 'w', 0o777)
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
        except Exception as e:
            self.logger.logMessage("JSONLDHarvester (storeHarvestData) %s " % (str(repr(e))), "ERROR")


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


    def parse_element(self, root, j):
        if j is None:
            return
        if isinstance(j, dict):
            for key in j.keys():
                value = j[key]
                if isinstance(value, list):
                    for e in value:
                        keyFormatted = key.replace(' ', '')
                        keyFormatted = keyFormatted.replace('@', '')
                        elem = self.__xml.createElement(keyFormatted)
                        self.parse_element(elem, e)
                        root.appendChild(elem)
                else:
                    if key.isdigit():
                        elem = self.__xml.createElement('item')
                        elem.setAttribute('value', key)
                    else:
                        keyFormatted = key.replace(' ', '')
                        keyFormatted = keyFormatted.replace('@', '')
                        elem = self.__xml.createElement(keyFormatted)
                    self.parse_element(elem, value)
                    root.appendChild(elem)
        elif isinstance(j, str):
            text = self.__xml.createTextNode(j)
            root.appendChild(text)
        elif isinstance(j, numbers.Number):
            text = self.__xml.createTextNode(str(j))
            root.appendChild(text)
        else:
            raise Exception("bad type %s for %s" % (type(j), j,))



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