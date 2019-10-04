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

    retryCount = 0
    pageCount = 1
    maxRecords = 100
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
                    "PURE (getHarvestData), getting data url:%s" %(request_url),
                    "DEBUG")
                self.data = getRequest.getData()
                self.getRecordCount()
                if self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                    self.completed = True
                self.retryCount = 0
                break
            except Exception as e:
                self.retryCount += 1
                if self.retryCount > 4:
                    self.errored = True
                    self.handleExceptions("ERROR RECEIVING PURE DATA, retry:%s, error: %s, url:%s"
                                %(str(self.retryCount), str(repr(e)), request_url))
                else:
                    self.logger.logMessage("ERROR RECEIVING PURE DATA, retry:%s, error: %s, url:%s"
                                %(str(self.retryCount), str(repr(e)), request_url), "ERROR")
                    time.sleep(1)
        del getRequest


    def getRequestUrl(self):
        parsed_url = urlparse.urlparse(self.harvestInfo['uri'])
        urlParams = urlparse.parse_qs(parsed_url.query)
        try:
            if isinstance(urlParams['apiKey'], list):
                urlParams['apiKey'] = urlParams['apiKey'][0]
        except KeyError:
            pass

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
        urlParams['pageSize'] = str(self.maxRecords)
        urlParams['page'] = str(self.pageCount)
        query = urllib.parse.urlencode(urlParams)
        return "%s://%s%s?%s" %(parsed_url.scheme, parsed_url.netloc, parsed_url.path, query)

    def storeHarvestData(self):
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