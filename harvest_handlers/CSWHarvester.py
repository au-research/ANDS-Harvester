from Harvester import *
import urllib
from xml.dom.minidom import parseString
import urllib.parse as urlparse

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
    pageCount = 0
    maxRecords = 100
    firstCall = True
    numberOfRecordsReturned = 0
    nextRecord = 0
    startPosition = 0
    urlParams = {}

    def harvest(self):
        """
        using the common harvest procedure
        iteratively retrieve and store data until we have retrieved them all
        """
        self.setupdirs()
        self.data = None
        self.updateHarvestRequest()
        self.setUpCrosswalk()
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
        """
        requests a set of "maxRecords" (100) until there are no more records to be retrieved
        :return:
        :rtype:
        """
        if self.stopped:
            return
        query = self.getParamString()
        getRequest = Request(self.harvestInfo['uri'] + query)
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
        except Exception as e:
            self.logger.logMessage("ERROR RECEIVING CSW DATA, %s," % str(repr(e)), "ERROR")
            self.handleExceptions(e, True)
        del getRequest


    def getParamString(self):
        """
        generates the url query params
        :return:
        :rtype:
        """
        if len(self.urlParams) == 0:
            try:
                urlParams = json.loads(self.harvestInfo['user_defined_params'])
                for item in urlParams:
                    self.urlParams[item['name']] = item['value']
            except KeyError as e:
                self.logger.logMessage("CSW user_defined_params are not set, revert to defaults")
            self.urlParams['outputSchema'] = self.harvestInfo['provider_type']
            self.urlParams['maxRecords'] = str(self.maxRecords)
        else:
            self.urlParams['startPosition'] = str(self.startPosition)
        query = urllib.parse.urlencode(self.urlParams)
        return '?' + query


    def checkNextRecord(self):
        """
        the purpose of this function is to determine if the harvest is completed
        if there are more records it sets the startPosition to the next record's start position
        otherwise sets it to zero and sets the harvest status completed
        :return:
        :rtype:
        """
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            try:
                nException = dom.getElementsByTagNameNS('http://www.opengis.net/ows', 'Exception')
                if len(nException) > 0:
                    eCode = nException[0].attributes["exceptionCode"].value
                    eTexts = nException[0].getElementsByTagNameNS('http://www.opengis.net/ows', 'ExceptionText')
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
                    "CSW (checkNextRecord parse Exception) %s" % str(repr(e)),
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








