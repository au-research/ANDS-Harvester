from Harvester import *

class PMHHarvester(Harvester):
    """
       {'harvester_method': {
        'id': 'PMHHarvester',
        'title': 'OAI-PMH Harvester to fetch metadata using OAI PMH protocol',
        'params': [
            {'name': 'url', 'required': 'true'},
            {'name': 'metadataPrefix', 'required': 'true'},
            {'name': 'set', 'required': 'false'},
            {'name': 'crosswalk', 'required': 'false'}
        ]
      }
    """
    __resumptionToken = False
    __from = "1900-01-01T12:00:00Z"
    __until = False
    __metadataPrefix = False
    __set = False
    __pageCount = 0

    def harvest(self):
        if self.harvestInfo['from_date'] != None:
            self.__from = parser.parse(self.harvestInfo['from_date']).isoformat() + 'Z'
        self.__until = datetime.now().isoformat() + 'Z'
        self.__metadataPrefix= self.harvestInfo['provider_type']
        self.__set = self.harvestInfo['oai_set']
        #self.setStatus('INIT')
        if self.harvestInfo['advanced_harvest_mode'] == 'INCREMENTAL':
            self.identifyRequest()
        self.setStatus("FIRST LIST_RECORDS CALL")
        self.getHarvestData()
        self.storeHarvestData()
        while self.__resumptionToken != False and self.__resumptionToken != "":
            self.getHarvestData()
            self.storeHarvestData()
        self.finishHarvest()

    def identifyRequest(self):
        getRequest = Request(self.harvestInfo['uri'] + '?verb=Identify')
        self.setStatus("IDENTIFY")
        try:
            self.data = getRequest.getData()
        except Exception as e:
            self.handleExceptions(e)
        try:
            dom = parseString(self.data)
            if dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue:
                self.__from = dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue
        except Exception:
            pass

    def getResumptionToken(self):
        if self.errored or self.stopped:
            return
        try:
            dom = parseString(self.data)
            if self.__resumptionToken != dom.getElementsByTagName('resumptionToken')[0].firstChild.nodeValue:
                self.__resumptionToken = dom.getElementsByTagName('resumptionToken')[0].firstChild.nodeValue
            else:
                self.__resumptionToken = False
        except Exception:
            pass


    def getHarvestData(self):
        if self.errored or self.stopped:
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
        self.setStatus("GETTING-OAI-DATA url:%s" %(self.harvestInfo['uri'] +  query) )
        try:
            self.data = getRequest.getData()
            self.getResumptionToken()
        except Exception as e:
            self.handleExceptions(e)
        del getRequest

    def storeHarvestData(self, fileExt='xml'):
        if self.errored or self.stopped:
            return
        directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id']) + os.sep + str(self.harvestInfo['harvest_id']) + os.sep + str(self.harvestInfo['batch_number']) + os.sep
        if not os.path.exists(directory):
            os.makedirs(directory)
        self.outputDir = directory
        dataFile = open(self.outputDir + str(self.__pageCount) + "." + fileExt, 'wb')
        self.setStatus("SAVING DATA: %s" %(self.outputDir + str(self.__pageCount) + "." + fileExt))
        dataFile.write(self.data)
        os.chmod(self.outputDir + str(self.__pageCount) + "." + fileExt, 777)
        dataFile.close()
        self.__pageCount = self.__pageCount + 1