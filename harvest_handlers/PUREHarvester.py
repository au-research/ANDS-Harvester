from Harvester import *
import urllib
from xml.dom.minidom import parseString
import urllib.parse as urlparse
class PUREHarvester(Harvester):
    """
       {
            "id": "PUREHarvester",
            "title": "PURE Harvester",
            "description": "Retrieving xml from PURE",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "identifier_prefix", "required": "true"},
                {"name": "api_key", "required": "true"},
                {"name": "xsl_file", "required": "false"}

            ]
      }
    """

    pageCount = 1
    maxRecords = 100
    firstCall = True
    numberOfRecordsReturned = 0

    def harvest(self):
        """
        The PURE Harvester uses page and pageSize to harvest records until no more records returned
        """
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
        """
        gets a set of "maxRecords" records from PURE using the page pageSize params
        :return:
        :rtype:
        """
        if self.stopped:
            return
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)
        try:
            self.firstCall = False
            self.setStatus("HARVESTING", "getting data url:%s" %(request_url))
            self.logger.logMessage(
                "PURE (getHarvestData), getting data url:%s" %(request_url),
                "DEBUG")
            self.data = getRequest.getData()
            self.getRecordCount()
            if self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                self.completed = True
        except Exception as e:
            self.logger.logMessage("ERROR RECEIVING PURE DATA, retry:%s, error: %s, url:%s"
                            %(str(self.retryCount), str(repr(e)), request_url), "ERROR")
            self.handleExceptions(e, True)

        del getRequest


    def getRequestUrl(self):
        """
        the url is constructed based on params provided by the harvest configuration
        that can be included in the url or added individually as user_defined_params
        the page param is derived from the pageCount variable that is auto-incremented after each successful call
        :return:
        :rtype:
        """
        parsed_url = urlparse.urlparse(self.harvestInfo['uri'])
        urlParams = urlparse.parse_qs(parsed_url.query)
        try:
            if isinstance(urlParams['apiKey'], list):
                urlParams['apiKey'] = urlParams['apiKey'][0]
        except KeyError:
            pass

        try:
            if isinstance(urlParams['pageSize'], list):
                urlParams['pageSize'] = urlParams['pageSize'][0]
        except KeyError:
            urlParams['pageSize'] = str(self.maxRecords)

        #pageSize apiKey can be defined by the datasource page

        try:
            params = json.loads(self.harvestInfo['user_defined_params'])
            for item in params:
                urlParams[item['name']] = item['value']
        except KeyError:
            pass
        try:
            if self.harvestInfo['apiKey'] :
                urlParams['apiKey'] = self.harvestInfo['apiKey']
        except KeyError:
            pass

        urlParams['page'] = str(self.pageCount)
        query = urllib.parse.urlencode(urlParams)
        return "%s://%s%s?%s" %(parsed_url.scheme, parsed_url.netloc, parsed_url.path, query)

    def storeHarvestData(self):
        """
        stores data only if numberOfRecordsReturned is greater than 0
        :return:
        :rtype:
        """
        if self.stopped or self.numberOfRecordsReturned == 0:
            return
        try:
            dataFile = open(self.outputDir + os.sep + str(self.pageCount) + "." + self.storeFileExtension , 'w', 0o777)
            self.setStatus("HARVESTING" , "saving file %s" %(self.outputDir + os.sep + str(self.pageCount) + "." + self.storeFileExtension))
            dataFile.write(self.data)
            dataFile.close()
            self.pageCount = self.pageCount + 1
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("PURE (storeHarvestData) %s " % (str(repr(e))), "ERROR")

    def getRecordCount(self):
        """
        the number of records are determined by the number of elements called 'dataSet'

        :return:
        :rtype:
        """
        self.numberOfRecordsReturned = 0
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            self.numberOfRecordsReturned = int(len(dom.getElementsByTagName('dataSet')))
            self.logger.logMessage("PURE (numberOfRecordsReturned) %s " % (self.numberOfRecordsReturned), "DEBUG")
        except Exception:
            self.numberOfRecordsReturned = 0
            pass
        self.recordCount += self.numberOfRecordsReturned