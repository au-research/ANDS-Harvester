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
    __xsl = myconfig.run_dir + 'xslt/data.gov.au_json_to_rif-cs.xsl'
    def harvest(self):
        self.__xml = Document()
        self.getPackageList()
        self.getPackageItems()
        self.storeHarvestData("ckan")
        self.transformToRifcs()
        self.finishHarvest()

    def getPackageList(self):
        if self.errored or self.stopped:
            return
        getRequest = Request(self.harvestInfo['uri'] +  self.__listQuery)
        self.setStatus("GETTING-PACKAGE-LIST url:" + self.harvestInfo['uri'] +  self.__listQuery)
        try:
            package = json.loads(getRequest.getData().decode("UTF-8"))
            if isinstance(package, dict):
                self.__packageList = package['result']
        except Exception as e:
            self.handleExceptions(e)
            return
        del getRequest

    def getPackageItems(self):
        if self.errored or self.stopped:
            return
        getRequest = Request(self.harvestInfo['uri'] +  self.__itemQuery)
        ePackages = self.__xml.createElement('datasets')
        self.__xml.appendChild(ePackages)
        try:
            for itemId in self.__packageList:
                if self.errored or self.stopped:
                    break
                data_string = urllib2.quote(json.dumps({'id': itemId}))
                self.setStatus("GETTING-PACKAGE item:" + itemId)
                package = json.loads(getRequest.postData(data_string.encode('UTF-8')).decode("UTF-8"))
                if isinstance(package, dict):
                    ePackage = self.__xml.createElement('result')
                    ePackage.setAttribute('id', itemId)
                    self.parse_element(ePackage, package['result'])
                    ePackages.appendChild(ePackage)
                    #break for test
        except Exception as e:
            self.handleExceptions(e)
        self.data = self.__xml.toprettyxml(encoding='utf-8', indent=' ')
        #self.setStatus("GETTING-PACKAGE url:" + self.harvestInfo['uri'] +  self.__listQuery)
        #try:
         #   self.__packageList = json.loads(getRequest.getData())
        #except Exception as e:
        #    self.handleExceptions(e)
        #    return
        #del getRequest

    def transformToRifcs(self):
        if self.errored or self.stopped:
            return
        self.setStatus("RUNNING CROSSWALK")
        transformerConfig = {'xsl': self.__xsl, 'outFile' : self.outputDir + "rifcs.xml", 'inFile' : self.outputFilePath}
        tr = XSLT2Transformer(transformerConfig)
        tr.transform()
        print(self.outputDir + "rifcs.xml")


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
