from Harvester import *
import urllib
import urllib.parse as urlparse
import array as arr
class ARCQUERYHarvester(Harvester):
    """
       {
            "id": "ARCQUERYHarvester",
            "title": "ARCQUERY Harvester",
            "description": "Retrieving JSON from ARC by rows of 400",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    # the number of pages the harvester received
    pageCount = 0
    pageCall = 1
    # the total records the harvester received
    totalCount = 0
    # the parameter "rows" and value that is passed in the request
    rows = 400
    # the number of records received in the current request
    numberOfRecordsReturned = 0

    __grantList = []

    def harvest(self):
        self.setupdirs()
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.data = None
        self.numberOfRecordsReturned = 1
        while not self.errored and not self.completed and not self.stopped \
                and self.numberOfRecordsReturned > 0:
            self.getGrantList()
            self.getHarvestData()
            self.storeHarvestData()
            self.pageCount += 1
            # give the server a break
            time.sleep(1)
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()


    def getGrantList(self):
        """
        Using the arc grants portal  query we can obtain the identifiers all items the dataportal server provides and group them by page size
        :return:
        :rtype:
        """

        if self.stopped:
            return
       # while not self.errored and not self.completed and not self.stopped:
        request_url = self.getRequestUrl()
        getRequest = Request(request_url)
        self.setStatus("HARVESTING")
        # we will collect grantids from the output page by page for later processing
        try:
            self.data = getRequest.getData()
            self.pageCall += 1
            package = json.loads(self.data);
            self.getRecordCount()
            if isinstance(package, dict):
                i=0
                while i < len(package['data']):
                    self.__grantList.append(package['data'][i]['id'])
                    i += 1
                # check if the collection of ids is completed by receiving nothing or more than the test limit
                if self.numberOfRecordsReturned == 0 or (
                        self.harvestInfo['mode'] == 'TEST' and self.recordCount >= myconfig.test_limit):
                    self.completed = True
        except Exception as e:
            self.handleExceptions(e)
            return
        del getRequest


    def getHarvestData(self):
        """
        gets  ARC SOLR results in JSON format for each item in the self.__grantsList (list of list per page)
        :return:
        """
        self.__xml = Document()

        if self.stopped:
            return
        baseUrl = self.harvestInfo['uri']
        getRequest = Request(baseUrl)
        eGrants = self.__xml.createElement('grants')
        self.__xml.appendChild(eGrants)
        self.listSize = len(self.__grantList)
        self.logger.logMessage("self.listSize: (%s)" % str(self.listSize), "DEBUG")
        for grantId in self.__grantList:
            self.recordCount += 1
            if self.stopped:
                break
            self.setStatus("HARVESTING", 'getting arc record: %s' % grantId)
            try:
                getRequest.setURL(baseUrl + "/" + grantId)
                grantJson = json.loads(getRequest.getData())
                if isinstance(grantJson, dict):
                    eGrant = self.__xml.createElement('grant')
                    eGrant.setAttribute('uri', grantJson['links']['self'])
                    self.parse_element(eGrant, grantJson['data'])
                    eGrants.appendChild(eGrant)
                if self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                    break
            except Exception as e:
                self.errored = True
                self.errorLog = self.errorLog + "\nERROR RECEIVING ITEM:%s, " % itemId
                self.handleExceptions(e, terminate=False)
                self.logger.logMessage("ERROR RECEIVING ITEM (%s/%s)" % (str(repr(e)), itemId), "ERROR")
            # get harvestData calls storeHarvestData for each page list
        self.data = str(self.__xml.toprettyxml(encoding='utf-8', indent=' '), 'utf-8')





    def getRequestUrl(self):
        """
        append the start and limit to the end of the query
        :return url:
        """
        urlParams = {}
        urlParams['page[number]'] = str(self.pageCall)
        urlParams['page[size]'] = self.rows

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
            self.totalCount = int(data['meta']['total-size'])

            if self.totalCount > 0:
                self.numberOfRecordsReturned = int(data['meta']['actual-page-size'])

            self.logger.logMessage("ARC Harvester (numberOfRecordsReturned) %d of %d" % ((self.numberOfRecordsReturned * self.pageCount), self.totalCount), "DEBUG")
            # sanity check
            self.recordCount += self.numberOfRecordsReturned
            if self.recordCount >= self.totalCount:
                self.logger.logMessage(" ARC Harvester (Harvest Completed)", "DEBUG")
                self.completed = True
        except Exception:
            self.numberOfRecordsReturned = 0
            self.errored = True
            pass
