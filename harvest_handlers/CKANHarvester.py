from Harvester import *
import numbers
import urllib.parse as urlparse
from xml.dom.minidom import Document
class CKANHarvester(Harvester):
    """
       {
            "id": "CKANHarvester",
            "title": "CKAN Harvester",
            "description": "CKAN Harvester to fetch JSON metadata using the CKAN API",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    __packageList = {}
    __listQuery = "api/3/action/package_list"
    __itemQuery = "api/3/action/package_show"


    def harvest(self):
        """
        the harvest method is a lot different from most harvest handlers
        the pagelist is generated and for each page the content is serialized as XML
        and appended to a dom document
        once all items received the XML document is stored
        and the harvest is completed
        """
        self.setupdirs()
        self.pageCount = 1
        self.data = None
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.__xml = Document()
        self.getPackageList()
        self.getPackageItems()
        self.storeHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def getPackageList(self):
        """
        Using the package list query we identifier all items the CKAN server provides
        :return:
        :rtype:
        """
        if self.stopped:
            return
        getRequest = Request(self.harvestInfo['uri'] +  self.__listQuery)
        self.setStatus("HARVESTING")
        try:
            package = json.loads(getRequest.getData())
            if isinstance(package, dict):
                self.__packageList = package['result']
        except Exception as e:
            self.handleExceptions(e)
            return
        del getRequest

    def getPackageItems(self):
        """
        using the package show service endpoint request all items from the list
        convert the response JSON to a DOM ELEMENT
        append the DOM ELEMENT to a XML DOCUMENT
        once all records are retrieved
        it stores resuklt Document into te data variable (as String)
        :return:
        :rtype:
        """
        if self.stopped:
            return
        time.sleep(0.1)
        baseUrl = self.harvestInfo['uri'] +  self.__itemQuery
        getRequest = Request(baseUrl)
        ePackages = self.__xml.createElement('datasets')
        self.__xml.appendChild(ePackages)
        self.listSize = len(self.__packageList)
        self.logger.logMessage("self.listSize: (%s)" % str(self.listSize), "DEBUG")
        self.recordCount = 0
        storeeditemId = 0
        params = {}
        try:
            for itemId in self.__packageList:
                self.recordCount += 1
                if self.stopped:
                    break
                data_string = json.dumps({'id': itemId})
                self.setStatus("HARVESTING", 'getting ckan record: %s' % itemId)
                storeeditemId = itemId
                try:
                    params['id'] = itemId
                    query = urlparse.urlencode(params)
                    getRequest.setURL(baseUrl + "?" + query)
                    package = json.loads(getRequest.getData())
                    if isinstance(package, dict):
                        ePackage = self.__xml.createElement('result')
                        ePackage.setAttribute('id', itemId)
                        self.parse_element(ePackage, package['result'])
                        #self.logger.logMessage("DATA (%s)" % str(package['result']), "DEBUG")
                        ePackages.appendChild(ePackage)
                    if self.recordCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                        break

                except Exception as e:
                    self.errored = True
                    self.errorLog = self.errorLog + "\nERROR RECEIVING ITEM:%s, " %itemId
                    self.handleExceptions(e, terminate=False)
                    self.logger.logMessage("ERROR RECEIVING ITEM (%s/%s)" % (str(repr(e)), itemId), "ERROR")
        except Exception as e:
            self.errored = True
            self.logger.logMessage("ERROR WHILE RECEIVING ITEM (%s/%s)" %(self.recordCount, storeeditemId), "ERROR")
            self.handleExceptions(e)
        self.data = str(self.__xml.toprettyxml(encoding='utf-8', indent=' '), 'utf-8')
