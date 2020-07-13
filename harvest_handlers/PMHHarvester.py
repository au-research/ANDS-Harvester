from Harvester import *
from xml.dom.minidom import parseString
class PMHHarvester(Harvester):
    """
        {
            "id": "PMHHarvester",
            "title": "OAI-PMH Harvester",
            "description": "OAI-PMH Harvester to fetch metadata using OAI PMH protocol",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "provider_type", "required": "true"},
                {"name": "oai_set", "required": "false"},
                {"name": "xsl_file", "required": "false"}
            ]
        }
    """
    __resumptionToken = ""
    __from = None
    __until = None
    __metadataPrefix = ""
    __set = None
    firstCall = True
    noRecordsMatchCodeValue = 'noRecordsMatch'


    def harvest(self):
        """
        The OAI-PMH Harvester allows incremental harvest by allowing the usage of from and until in its parameters
        if harvest mode is INCREMENTAL it uses the last harvest date for this datasource
        it
        """
        self.setupdirs()
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.data = None
        self.__until = datetime.fromtimestamp(self.startUpTime, timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        self.__metadataPrefix = self.harvestInfo['provider_type']
        try:
            self.__set = self.harvestInfo['oai_set']
        except KeyError:
            pass
        try:
            if self.harvestInfo['advanced_harvest_mode'] == 'INCREMENTAL':
                if self.harvestInfo['last_harvest_run_date'] != '':
                    self.__from = self.harvestInfo['last_harvest_run_date']
                else:
                    self.identifyRequest()
            while self.firstCall or self.__resumptionToken != "":
                time.sleep(0.1)
                self.getHarvestData()
                self.storeHarvestData()
            self.runCrossWalk()
            self.postHarvestData()
            self.finishHarvest()
        except Exception as e:
            self.logger.logMessage("ERROR RECEIVING OAI DATA, resumptionToken:%s" % self.__resumptionToken, "ERROR")
            self.handleExceptions(e)

    def identifyRequest(self):
        """
        used only if from date is required but no last harvest date is given
        If unable to find earliestDatestamp then just leave from as None and get everything
        """

        getRequest = Request(self.harvestInfo['uri'] + '?verb=Identify')
        self.setStatus("HARVESTING")
        try:
            data = getRequest.getData()
            dom = parseString(data)
            if dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue:
                self.__from = dom.getElementsByTagName('earliestDatestamp')[0].firstChild.nodeValue
        except Exception as e:
            self.logger.logMessage("ERROR PARSING IDENTIFY DOC OR 'earliestDatestamp' element is not found, url:%s"
                                   % (str(self.harvestInfo['uri'] + '?verb=Identify')), "ERROR")


    def getResumptionToken(self):
        """
        the resumptiontoken is the progress controller in OIA-PMH harvest
        it allows the harvester to continue a harvest from any point by providing a token instead of an page increment
        if no resumptionToken is given the harvest is completed
        the page count used in this case only to save the package as {pageCount}.xml
        INFO: some faulty implementation we found that the last resumption token is returned
        so we test is the resumptionToken is the same as the previous one to determine if the harvest has completed
        :return:
        :rtype:
        """
        if self.stopped:
            return
        try:
            dom = parseString(self.data)
            try:
                error = dom.getElementsByTagName('error')
                if len(error) > 0:
                    e = "ERROR RECEIVED FROM PROVIDER: "
                    e += error[0].firstChild.nodeValue
                    errorCode = error[0].attributes["code"].value
                    if errorCode == self.noRecordsMatchCodeValue:
                        if not self.firstCall:
                            self.__resumptionToken = ""
                        else:
                            self.handleNoRecordsMatch(errorCode)
                    else:
                        self.handleExceptions(e, True)
                    return
            except Exception as e:
                pass
            metadataElList = dom.getElementsByTagName('metadata')
            self.recordCount = self.recordCount + len(metadataElList)
            self.pageCount = self.pageCount + 1
            if len(metadataElList) > 0:
                self.__resumptionToken = dom.getElementsByTagName('resumptionToken')[0].firstChild.nodeValue
            else:
                # if no more metadata is received then stop harvest
                self.__resumptionToken = ""

            if self.pageCount >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                # also end if reached the test limit in test mode
                self.__resumptionToken = ""

        except Exception:
            self.__resumptionToken = ""
            pass


    def getHarvestData(self):
        """
        retrieves a set of records
        stores it in the data variable
        :return:
        :rtype:
        """
        if self.stopped:
            return
        query = "?verb=ListRecords"
        if self.__resumptionToken != "":
            query += "&resumptionToken=" + self.__resumptionToken
        else:
            query += '&metadataPrefix=' + self.__metadataPrefix
            # __until is always now
            if self.__from is not None:
                query += '&from=' + self.__from
                query += '&until=' + self.__until
            if self.__set:
                query += '&set='+ self.__set
        getRequest = Request(self.harvestInfo['uri'] + query)
        try:
            self.logger.logMessage("\nHARVESTING getting data url:%s" %(self.harvestInfo['uri'] + query), "DEBUG")
            self.setStatus("HARVESTING", "getting data url:%s" %(self.harvestInfo['uri'] + query))
            self.data = getRequest.getData()
            self.getResumptionToken()
            self.firstCall = False
        except Exception as e:
            self.errored = True
            self.handleExceptions(e, True)
            self.logger.logMessage("ERROR RECEIVING OAI DATA, %s" % str(repr(e)), "ERROR")
        del getRequest




