from Harvester import *

class CKANHarvester(Harvester):
    """
       {'harvester_method': {
        'id': 'CKANHarvester',
        'title': 'CKAN Harvester to fetch JSON metadata using the CKAN API',
        'params': [
            {'name': 'url', 'required': 'true'},
            {'name': 'crosswalk', 'required': 'false'}
        ]
      }
    """
    __packageList = {}
    __listQuery = "api/action/package_list"
    __itemQuery = "api/action/package_show"
    __xml = False
    __xsl = myconfig.run_dir + '/xslt/data.gov.au_json_to_rif-cs.xsl'
    def harvest(self):
        self.__xml = Document()
        self.getPackageList()
        self.getPackageItems()
        self.storeHarvestData("ckan")
        self.transformToRifcs()
        self.postHarvestData()
        self.finishHarvest()

    def getPackageList(self):
        if self.stopped:
            return
        getRequest = Request(self.harvestInfo['uri'] +  self.__listQuery)
        self.setStatus("HARVESTING")
        try:
            package = json.loads(getRequest.getData().decode("UTF-8"))
            if isinstance(package, dict):
                self.__packageList = package['result']
        except Exception as e:
            self.handleExceptions(e)
            return
        del getRequest

    def getPackageItems(self):
        if self.stopped:
            return
        time.sleep(0.1)
        getRequest = Request(self.harvestInfo['uri'] +  self.__itemQuery)
        ePackages = self.__xml.createElement('datasets')
        self.__xml.appendChild(ePackages)
        self.listSize = len(self.__packageList)
        self.recordCount = 0
        try:
            for itemId in self.__packageList:
                #time.sleep(1)
                if self.stopped:
                    break
                data_string = urllib2.quote(json.dumps({'id': itemId}))
                self.setStatus("HARVESTING", 'getting ckan record: %s' %itemId)
                try:
                    package = json.loads(getRequest.postData(data_string.encode('UTF-8')).decode("UTF-8"))
                    if isinstance(package, dict):
                        ePackage = self.__xml.createElement('result')
                        ePackage.setAttribute('id', itemId)
                        self.parse_element(ePackage, package['result'])
                        ePackages.appendChild(ePackage)
                    self.recordCount = self.recordCount + 1
                except Exception as e:
                    self.errored = True
                    self.errorLog = self.errorLog + "\nERROR RECEIVING ITEM:%s" %itemId
                    self.handleExceptions(e, terminate=False)
                    self.logger.logMessage("ERROR RECEIVING ITEM (%s/%s)" %(self.recordCount,itemId))
        except Exception as e:
            self.errored = True
            self.logger.logMessage("ERROR WHILE RECEIVING ITEM (%s/%s)" %(self.recordCount,itemId))
            self.handleExceptions(e)
        self.data = self.__xml.toprettyxml(encoding='utf-8', indent=' ')
        #self.setStatus("GETTING-PACKAGE", "url:" + self.harvestInfo['uri'] +  self.__listQuery)
        #try:
         #   self.__packageList = json.loads(getRequest.getData())
        #except Exception as e:
        #    self.handleExceptions(e)
        #    return
        #del getRequest

    def transformToRifcs(self):
        if self.stopped:
            return
        outFile = self.outputDir  + os.sep + str(self.harvestInfo['batch_number']) + ".xml"
        self.setStatus("HARVESTING", "RUNNING CROSSWALK")
        transformerConfig = {'xsl': self.__xsl, 'outFile' : outFile, 'inFile' : self.outputFilePath}
        tr = XSLT2Transformer(transformerConfig)
        tr.transform()



    def parse_element(self, root, j):
        if j is None:
            return
        if isinstance(j, dict):
            for key in j.keys():
                value = j[key]
                if isinstance(value, list):
                    for e in value:
                        elem = self.__xml.createElement(key)
                        self.parse_element(elem, e)
                        root.appendChild(elem)
                else:
                    if key.isdigit():
                        elem = self.__xml.createElement('item')
                        elem.setAttribute('value', key)
                    else:
                        elem = self.__xml.createElement(key)
                    self.parse_element(elem, value)
                    root.appendChild(elem)
        elif isinstance(j, str):
            text = self.__xml.createTextNode(j)
            root.appendChild(text)
        elif isinstance(j, numbers.Number):
            text = self.__xml.createTextNode(str(j))
            root.appendChild(text)
        else:
            raise Exception("bad type %s for %s" % (type(j), j,))
