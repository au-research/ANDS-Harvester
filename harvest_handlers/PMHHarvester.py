from Harvester import *
from xml.dom.minidom import parseString
class PMHHarvester(Harvester):
    """
        {
            "id": "PMHHarvester",
            "title": "OAI-PMH Harvester",
            "description": "OAI-PMH Harvester to fetch metadata using OAI PMH protocol",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "provider_type", "required": "true"},
                {"name": "oai_set", "required": "false"},
                {"name": "xsl_file", "required": "false"}
            ]
        }
    """
    __resumptionToken = False
    __from = "1900-01-01T00:00:00Z"
    __until = False
    __metadataPrefix = False
    __set = False
    retryCount = 0
    firstCall = True
    noRecordsMatchCodeValue = 'noRecordsMatch'


    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.outputDir = self.outputDir + os.sep + str(self.harvestInfo['batch_number'])
        if not os.path.exists(self.outputDir):
            os.makedirs(self.outputDir)

    def harvest(self):
        self.cleanPreviousHarvestRecords()
        now = datetime.now().replace(microsecond=0)
        self.__until = datetime.fromtimestamp(self.startUpTime, timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        self.__metadataPrefix= self.harvestInfo['provider_type']
        try:
            self.__set = self.harvestInfo['oai_set']
        except KeyError:
            pass
        try:
            if self.harvestInfo['advanced_harvest_mode'] == 'INCREMENTAL':
                if self.harvestInfo['last_harvest_run_date'] != '':
                    self.__from = self.harvestInfo['last_harvest_run_date']
                else:
                    self.identifyRequest()
            while self.firstCall or (self.__resumptionToken is not False and self.__resumptionToken != ""):
                time.sleep(0.1)
                self.getHarvestData()
                self.storeHarvestData()
            self.runCrossWalk()
            self.postHarvestData()
            self.finishHarvest()
        except Exception as e:
            self.logger.logMessage("ERROR RECEIVING OAI DATA, resumptionToken:%s" %(self.__resumptionToken), "ERROR")
            self.handleExceptions(e)

    def identifyRequest(self):
        getRequest = Request(self.harvestInfo['uri'] + '?verb=Identify')
        self.setStatus("HARVESTING")
        try:
            data = getRequest.getData()
        except Exception as e:
            self.handleExceptions(e)
        try:
            dom = parseString(data)
            if dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue:
                self.__from = dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue
        except Exception as e:
            self.logger.logMessage("ERROR PARSING IDENTIFY DOC OR 'earliestDatestamp' element is not found, url:%s" %(str(self.harvestInfo['uri'] + '?verb=Identify')), "ERROR")
            self.handleExceptions(e)

    def getResumptionToken(self):
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            try:
                error = dom.getElementsByTagName('error')
                if len(error) > 0:
                    e = "ERROR RECEIVED FROM PROVIDER: "
                    e += error[0].firstChild.nodeValue
                    errorCode = error[0].attributes["code"].value
                    if errorCode == self.noRecordsMatchCodeValue:
                        if not self.firstCall:
                            self.__resumptionToken = False
                        else:
                            self.handleNoRecordsMatch(errorCode)
                    else:
                        self.handleExceptions(e, True)
                    return
            except Exception as e:
                pass
            metadataElList = dom.getElementsByTagName('metadata')
            self.recordCount = self.recordCount + len(metadataElList)
            self.pageCount = self.pageCount + 1
            if self.__resumptionToken != dom.getElementsByTagName('resumptionToken')[0].firstChild.nodeValue:
                self.__resumptionToken = dom.getElementsByTagName('resumptionToken')[0].firstChild.nodeValue
            else:
                self.__resumptionToken = False

            if self.pageCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                self.__resumptionToken = False

        except Exception:
            self.__resumptionToken = False
            pass


    def getHarvestData(self):
        if self.stopped:
            return
        query = "?verb=ListRecords"
        if self.__resumptionToken and self.__resumptionToken != "":
            query += "&resumptionToken="+ self.__resumptionToken
        else:
            query += '&metadataPrefix='+ self.__metadataPrefix
            if self.harvestInfo['advanced_harvest_mode'] == 'INCREMENTAL':
                query += '&from='+ self.__from
                query += '&until='+ self.__until
            if self.__set:
                query += '&set='+ self.__set
        getRequest = Request(self.harvestInfo['uri'] +  query)
        try:
            self.logger.logMessage("\nHARVESTING getting data url:%s" %(self.harvestInfo['uri'] +  query), "DEBUG")
            self.setStatus("HARVESTING", "getting data url:%s" %(self.harvestInfo['uri'] +  query))
            self.data = getRequest.getData()
            self.getResumptionToken()
            self.firstCall = False
            self.retryCount = 0
        except Exception as e:
            self.retryCount += 1
            time.sleep(1)
            if self.retryCount > 4:
                self.errored = True
                self.handleExceptions(e)
            self.logger.logMessage("ERROR RECEIVING OAI DATA, retry:%s, url:%s" %(str(self.retryCount), self.harvestInfo['uri'] +  query), "ERROR")
        del getRequest

    def storeHarvestData(self):
        if self.stopped or not(self.data):
            return
        try:
            dataFile = open(self.outputDir + os.sep + str(self.pageCount) + "." + self.storeFileExtension, 'w', 0o777)
            dataFile.write(self.data)
            dataFile.close()
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("PMH (storeHarvestData) %s " % (str(repr(e))), "ERROR")


    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] == None or self.harvestInfo['xsl_file'] == '':
            return
        outFile = self.outputDir  + os.sep + str(self.pageCount) + "." + self.resultFileExtension
        inFile = self.outputDir  + os.sep + str(self.pageCount) + "." + self.storeFileExtension
        #self.setStatus("HARVESTING", "RUNNING CROSSWALK")
        try:
            transformerConfig = {'xsl': self.harvestInfo['xsl_file'], 'outFile' : outFile, 'inFile' : inFile}
            tr = XSLT2Transformer(transformerConfig)
            tr.transform()
        except subprocess.CalledProcessError as e:
            self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()), "ERROR")
            self.handleExceptions("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()))
        except Exception as e:
            self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK", "ERROR")
            self.handleExceptions(e)
