from Harvester import *
import urllib
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
    # the number of pages the harvester received
    pageCount = 0
    # the total records the harvester received
    totalCount = 0
    # the parameter "rows" and value that is passed in the request
    rows = 400
    # the number of records received in the current request
    numberOfRecordsReturned = 0

    def harvest(self):
        self.setupdirs()
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.startPosition = 0
        self.data = None
        # keep harvesting until something terminates the harvest
        # zero records returned
        # error occurred
        # stopped by the registry
        # completed
        # set the self.numberOfRecordsReturned greater than 0 before first call
        self.numberOfRecordsReturned = 1
        while not self.errored and not self.completed and not self.stopped \
                and self.numberOfRecordsReturned > 0:
            self.getHarvestData()
            self.storeHarvestData()
            # give the server a break
            time.sleep(1)
        # after finishing all request
        # run crosswalk (if defined)
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()


    def getHarvestData(self):
        """
        gets a set of 400 CKAN results in JSON format
        :return:
        """
        if self.stopped:
            return
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)

        try:
            self.setStatus("HARVESTING", "getting data url:%s" %(request_url))
            self.logger.logMessage(
                "CKANQUERY (getHarvestData), getting data url:%s" %(request_url),
                "DEBUG")
            self.data = getRequest.getData()
            # find out how many result we have received
            self.getRecordCount()
            # check if the harvest is completed by receiving nothing or more than the test limit
            if self.numberOfRecordsReturned == 0 or (self.harvestInfo['mode'] == 'TEST' and self.recordCount >= myconfig.test_limit):
                self.completed = True
        except Exception as e:
                self.logger.logMessage("ERROR RECEIVING CKANQUERY DATA,  %s" % str(repr(e)), "ERROR")
        del getRequest


    def getRequestUrl(self):
        """
        append the start and rows to the end of the query
        :return url:
        """
        urlParams = {}
        urlParams['rows'] = self.rows
        urlParams['start'] = self.rows * self.pageCount

        query = urllib.parse.urlencode(urlParams)
        return self.harvestInfo['uri'] + "&" + query

    def getRecordCount(self):
        """
        checks if the request is successful and determines the record count we received and increments the total count
        :return:
        """
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
            # sanity check
            self.recordCount += self.numberOfRecordsReturned
            if self.recordCount >= self.totalCount:
                self.logger.logMessage("CKANQUERY (Harvest Completed)", "DEBUG")
                self.completed = True
        except Exception:
            self.numberOfRecordsReturned = 0
            self.errored = True
            pass
