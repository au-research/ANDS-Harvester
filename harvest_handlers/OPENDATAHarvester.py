from Harvester import *
import urllib
import urllib.parse as urlparse
class OPENDATAHarvester(Harvester):
    """
       {
            "id": "OPENDATAHarvester",
            "title": "OPEN DATA API Harvester",
            "description": "Retrieving JSON from any service that implements the US Government Project Open Data API(for dataSets), by limit of 400",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    # the number of pages the harvester received
    pageCount = 0
    # the total records the harvester received
    recordCount = 0
    # the parameter "rows" and value that is passed in the request
    rows = 400
    # the number of records received in the current request
    numberOfRecordsReturned = 1


    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        # generic in-house xslt to convert (ACT Gov's) Open Data content to rifcs
        if self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == "":
            self.harvestInfo['xsl_file'] = myconfig.run_dir + "resources/open_data_to_rifcs.xsl"

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
        while not self.errored and not self.completed and not self.stopped \
                and self.numberOfRecordsReturned > 0:
            self.getHarvestData()
            if self.numberOfRecordsReturned > 0:
                self.storeHarvestData()
            # give the server a break
            time.sleep(1)
        # after finishing all request
        # run crosswalk (if defined)
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def setRows(self, row_size):
        self.rows = row_size

    def getHarvestData(self):
        """
        gets a set of 400 results in JSON format
        :return:
        """
        if self.stopped:
            return
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)
        try:
            self.setStatus("HARVESTING", "getting data url:%s" %(request_url))
            self.logger.logMessage(
                "OPEN DATA (getHarvestData), getting data url:%s" %(request_url),
                "DEBUG")
            self.data = getRequest.getData()
            # find out how many result we have received
            self.getRecordCount()
            # check if the harvest is completed by receiving nothing or more than the test limit
            if self.numberOfRecordsReturned < self.rows or self.numberOfRecordsReturned == 0 \
                    or (self.harvestInfo['mode'] == 'TEST' and self.recordCount >= myconfig.test_limit):
                self.logger.logMessage("OPENDATA Harvester (Harvest Completed)", "DEBUG")
                self.completed = True
        except Exception as e:
                self.logger.logMessage("ERROR RECEIVING  OPEN DATA DATA, %s" % str(repr(e)), "ERROR")
        del getRequest


    def getRequestUrl(self):
        """
        append the start and limit to the end of the query
        :return url:
        """
        urlParams = {}
        urlParams['limit'] = self.rows
        urlParams['page'] = self.pageCount

        query = urllib.parse.urlencode(urlParams)
        return self.harvestInfo['uri'] + "?" + query

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
            self.numberOfRecordsReturned = int(len(data))
            self.pageCount += 1
            self.recordCount += self.numberOfRecordsReturned
            self.logger.logMessage("OPENDATA Harvester (numberOfRecordsReturned) %d totaling: %d" % ((self.numberOfRecordsReturned), self.recordCount), "DEBUG")
        except Exception:
            self.numberOfRecordsReturned = 0
            self.errored = True
            pass
