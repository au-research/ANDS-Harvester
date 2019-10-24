from Harvester import *
import urllib
from xml.dom.minidom import parseString
import urllib.parse as urlparse
class CKANQUERYHarvester(Harvester):
    """
       {
            "id": "CKANQUERYHarvester",
            "title": "CKANQUERY Harvester",
            "description": "Retrieving JSON from CKAN by rows of 400",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """

    retryCount = 0
    pageCount = 0
    totalCount = 0
    rows = 400
    firstCall = True
    numberOfRecordsReturned = 0

    def harvest(self):
        self.setupdirs()
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.startPosition = 0
        self.data = None
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
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)
        self.retryCount = 0
        while self.retryCount < 5:
            try:
                self.firstCall = False
                self.setStatus("HARVESTING", "getting data url:%s" %(request_url))
                self.logger.logMessage(
                    "CKANQUERY (getHarvestData), getting data url:%s" %(request_url),
                    "DEBUG")
                self.data = getRequest.getData()
                self.getRecordCount()
                if self.getRecordCount == 0 or (self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST'):
                    self.completed = True
                self.retryCount = 0
                break
            except Exception as e:
                self.retryCount += 1
                if self.retryCount > 4:
                    self.errored = True
                    self.handleExceptions("ERROR RECEIVING CKANQUERY DATA, retry:%s, error: %s, url:%s"
                                %(str(self.retryCount), str(repr(e)), request_url))
                else:
                    self.logger.logMessage("ERROR RECEIVING CKANQUERY DATA, retry:%s, error: %s, url:%s"
                                %(str(self.retryCount), str(repr(e)), request_url), "ERROR")
                    time.sleep(1)
        del getRequest


    def getRequestUrl(self):
        urlParams = {}
        urlParams['rows'] = self.rows
        urlParams['start'] = self.rows * self.pageCount
        query = urllib.parse.urlencode(urlParams)
        return self.harvestInfo['uri'] + "&" + query


    def getRecordCount(self):
        self.numberOfRecordsReturned = 0
        if self.stopped:
            return
        try:
            data = json.loads(self.data, strict=False)
            if data['success'] == 'true' or data['success'] == True:
                self.numberOfRecordsReturned = int(len(data['result']['results']))
                self.totalCount = int(data['result']['count'])
                self.pageCount += 1
            self.logger.logMessage("CKANQUERY (numberOfRecordsReturned) %d of %d" % ((self.numberOfRecordsReturned * self.pageCount), self.totalCount), "DEBUG")
            if self.recordCount + self.numberOfRecordsReturned >= self.totalCount:
                self.logger.logMessage("CKANQUERY (Harvest Completed)", "DEBUG")
                self.completed = True
        except Exception:
            self.numberOfRecordsReturned = 0
            pass
        self.recordCount += self.numberOfRecordsReturned