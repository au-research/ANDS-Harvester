from Harvester import *
import urllib
class CSWHarvester(Harvester):
    """
        {
            "id": "CSWHarvester",
            "title": "CSW Harvester",
            "description": "CSW Harvester to fetch metadata using Catalog Service for the Web protocol",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "provider_type", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
        }
    """
    __outputSchema = False
    retryCount = 0
    pageCount = 0
    maxRecords = 100
    firstCall = True
    numberOfRecordsReturned = 0
    nextRecord = 0
    startPosition = 0
    urlParams = {};

    defaultParams = {'request':'GetRecords',
        'service':'CSW',
        'version':'2.0.2',
        'namespace':'xmlns(csw=http://www.opengis.net/cat/csw)',
        'resultType':'results',
        'outputFormat':'application/xml',
        'typeNames':'csw:Record',
        'elementSetName':'full',
        'constraintLanguage':'CQL_TEXT',
        'constraint_language_version':'1.1.0v'
    }

    def harvest(self):
        self.urlParams = {}
        self.startPosition = 0
        while self.firstCall or(self.numberOfRecordsReturned > 0 and not(self.completed)):
            time.sleep(0.1)
            self.getHarvestData()
            self.storeHarvestData()
            self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getHarvestData(self):
        if self.stopped:
            return
        query = self.getParamString()
        getRequest = Request(self.harvestInfo['uri'] + query)
        self.retryCount = 0
        while self.retryCount < 5:
            try:
                self.firstCall = False
                self.setStatus("HARVESTING", "getting data url:%s" %(self.harvestInfo['uri'] + query))
                self.logger.logMessage(
                    "CSW (getHarvestData), getting data url:%s" %(self.harvestInfo['uri'] + query),
                    "DEBUG")
                self.data = getRequest.getData()
                self.checkNextRecord()
                if self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                    self.completed = True
                self.retryCount = 0
                break
            except Exception as e:
                self.retryCount += 1
                if self.retryCount > 4:
                    self.errored = True
                    self.handleExceptions("ERROR RECEIVING CSW DATA, retry:%s, error: %s, url:%s" %(str(self.retryCount), str(repr(e)), self.harvestInfo['uri'] +  query))
                else:
                    self.logger.logMessage("ERROR RECEIVING CSW DATA, retry:%s, error: %s, url:%s" %(str(self.retryCount), str(repr(e)), self.harvestInfo['uri'] +  query), "ERROR")
                    time.sleep(1)
        del getRequest

    def getParamString(self):
        if len(self.urlParams) == 0:
            try:
                urlParams = json.loads(self.harvestInfo['user_defined_params'])
                for item in urlParams:
                    self.urlParams[item['name']] = item['value']
            except KeyError as e:
                self.logger.logMessage("CSW user_defined_params are not set, revert to defaults")
            self.urlParams['outputSchema'] = self.harvestInfo['provider_type']
            self.urlParams['maxRecords'] = str(self.maxRecords)
            self.urlParams['request'] = self.urlParams.get('request', self.defaultParams['request'])
            self.urlParams['service'] = self.urlParams.get('service', self.defaultParams['service'])
            self.urlParams['version'] = self.urlParams.get('version', self.defaultParams['version'])
            self.urlParams['namespace'] = self.urlParams.get('namespace', self.defaultParams['namespace'])
            self.urlParams['resultType'] = self.urlParams.get('resultType', self.defaultParams['resultType'])
            self.urlParams['outputFormat'] = self.urlParams.get('outputFormat', self.defaultParams['outputFormat'])
            self.urlParams['typeNames'] = self.urlParams.get('typeNames', self.defaultParams['typeNames'])
            self.urlParams['elementSetName'] = self.urlParams.get('elementSetName', self.defaultParams['elementSetName'])
            self.urlParams['constraintLanguage'] = self.urlParams.get('constraintLanguage', self.defaultParams['constraintLanguage'])
            self.urlParams['constraint_language_version'] = self.urlParams.get('constraint_language_version', self.defaultParams['constraint_language_version'])
        else:
            self.urlParams['startPosition'] = str(self.startPosition)
        query = urllib.parse.urlencode(self.urlParams)
        return '?' + query

    def checkNextRecord(self):
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            self.logger.logMessage(
                "CSW (checkNextRecord parse response) %s" % str(self.data),
                "DEBUG")
            try:

                nException = dom.getElementsByTagNameNS('http://www.opengis.net/ows', 'Exception')
                self.logger.logMessage(
                    "CSW (checkNextRecord parse response) %s" % str(repr(nException)),
                    "DEBUG")
                if len(nException) > 0:
                    eCode = nException[0].attributes["exceptionCode"].value
                    #eLocator = nException.attributes["locator"].value
                    eTexts = nException[0].getElementsByTagNameNS('http://www.opengis.net/ows','ExceptionText')
                    eText = ''
                    for i, elem in enumerate(eTexts):
                        eText = eText + elem.firstChild.nodeValue
                    self.handleExceptions("ERROR RECEIVED FROM SERVER: (code: %s, value:%s)"%(eCode, eText))
                    self.logger.logMessage(
                        "ERROR RECEIVED FROM SERVER: (code: %s, value:%s)"%(eCode, eText),
                        "ERROR")
                    return
            except Exception as e:
                self.logger.logMessage(
                    "CSW (checkNextRecord parse response) %s" % str(repr(e)),
                    "ERROR")
                pass
            nSearchResult = dom.getElementsByTagName('csw:SearchResults')[0]
            if self.listSize == 'unknown':
                self.listSize = int(nSearchResult.attributes["numberOfRecordsMatched"].value)
            self.numberOfRecordsReturned = int(nSearchResult.attributes["numberOfRecordsReturned"].value)
            self.startPosition = int(nSearchResult.attributes["nextRecord"].value)
            if self.startPosition == 0:
                self.completed = True
            self.recordCount += self.numberOfRecordsReturned
            self.pageCount += 1
        except Exception as e:
            self.logger.logMessage(
                "CSW (checkNextRecord) %s" % str(repr(e)),
                "ERROR")
            self.startPosition = 0


    def storeHarvestData(self):
        if self.stopped or not(self.data):
            return
        try:
            directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id']) + os.sep + str(self.harvestInfo['batch_number']) + os.sep
            if not os.path.exists(directory):
                os.makedirs(directory)
            self.outputDir = directory
            dataFile = open(self.outputDir + str(self.pageCount) + "." + self.storeFileExtension , 'wb', 0o777)
            self.setStatus("HARVESTING" , "saving file %s" %(self.outputDir + str(self.pageCount) + "." + self.storeFileExtension))
            dataFile.write(self.data)
            dataFile.close()
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("PMH (storeHarvestData) %s " % (str(repr(e))), "ERROR")


    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        outFile = self.outputDir + str(self.pageCount) + "." + self.resultFileExtension
        inFile = self.outputDir + str(self.pageCount) + "." + self.storeFileExtension
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