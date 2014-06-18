from Harvester import *

class CSWHarvester(Harvester):
    """
        {
            "id": "CSWHarvester",
            "title": "CSW Harvester",
            "description": "CSW Harvester to fetch metadata using Catalog Service for the Web protocol",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "outputSchema", "required": "true"}
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
    def harvest(self):
        while self.firstCall or self.maxRecords == self.numberOfRecordsReturned or not(self.completed):
            time.sleep(0.1)
            self.getHarvestData()
            self.storeHarvestData()
            self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getHarvestData(self):
        if self.stopped:
            return
        query = "?request=GetRecords"
        query += "&service=CSW"
        query += "&version=2.0.2"
        query += "&namespace=xmlns(csw=http://www.opengis.net/cat/csw)"
        query += "&resultType=results"
        query += "&outputSchema=http://www.isotc211.org/2005/gmd"
        query += "&outputFormat=application/xml"
        query += "&maxRecords=" + str(self.maxRecords)
        if self.startPosition > 0:
            query += "&startPosition=" + str(self.startPosition)
        query += "&typeNames=csw:Record"
        query += "&elementSetName=full"
        query += "&constraintLanguage=CQL_TEXT"
        query += "&constraint_language_version=1.1.0v"

        getRequest = Request(self.harvestInfo['uri'] +  query)
        try:
            self.firstCall = False
            self.setStatus("HARVESTING", "getting data url:%s" %(self.harvestInfo['uri'] +  query))
            self.data = getRequest.getData()
            self.checkNextRecord()
            if self.recordCount >= myconfig.test_limit or self.harvestInfo['mode'] == 'TEST':
                self.completed = True
            self.retryCount = 0
        except Exception as e:
            self.errored = True
            self.retryCount += 1
            time.sleep(1)
            if self.retryCount > 4:
                self.handleExceptions(e)
            self.logger.logMessage("ERROR RECEIVING CSW DATA, retry:%s, url:%s" %(str(self.retryCount), self.harvestInfo['uri'] +  query))
        del getRequest

    def checkNextRecord(self):
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            nSearchResult = dom.getElementsByTagName('csw:SearchResults')[0]
            if self.listSize == 'unknown':
                self.listSize = int(nSearchResult.attributes["numberOfRecordsMatched"].value)
            self.numberOfRecordsReturned = int(nSearchResult.attributes["numberOfRecordsReturned"].value)
            self.startPosition = int(nSearchResult.attributes["nextRecord"].value)
            self.recordCount = self.recordCount + self.numberOfRecordsReturned
            self.pageCount += 1
        except Exception as e:
            print(repr(e))
            self.startPosition = 0


    def storeHarvestData(self):
        if self.stopped or not(self.data):
            return
        directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id']) + os.sep + str(self.harvestInfo['batch_number']) + os.sep
        if not os.path.exists(directory):
            os.makedirs(directory)
        self.outputDir = directory
        dataFile = open(self.outputDir + str(self.pageCount) + "." + self.storeFileExtension , 'wb', 0o777)
        self.setStatus("HARVESTING" , "saving file %s" %(self.outputDir + str(self.pageCount) + "." + self.storeFileExtension))
        dataFile.write(self.data)
        dataFile.close()