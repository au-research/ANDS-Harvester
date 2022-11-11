import base64
import urllib

from Harvester import *
from crawler.SiteMapCrawler import SiteMapCrawler
import json
from xml.dom.minidom import Document
from utils.Request import Request as myRequest
import asyncio
from timeit import default_timer
import urllib.parse as urlparse


class DataCiteQueryHarvester(Harvester):
    """
       {
            "id": "DataCiteQueryHarvester",
            "title": "DataCite Query Harvester",
            "description": "Data CiteQuery Harvester returns the DOI metadata that matches the query",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "true"}
            ]
      }
    """
    # the list of DOIs the query has found
    doiList = []
    # the number of pages stored per batchfile
    batchSize = 400
    # the number of simultaneous connections
    tcp_connection_limit = 5
    # use to benchmark asyncio vs grequest vs request
    start_time = {}
    # request header; some servers refuse to respond unless User-Agent is given
    headers = {'User-Agent': 'ARDC Harvester'}

    data = []
    searchResults = []
    totalCount = 0
    recordCount = 0


    def __init__(self, harvestInfo):
        super().__init__(harvestInfo)
        self.data = []
        self.doiList = []
        try:
            if self.harvestInfo['requestHandler']:
                pass
        except KeyError:
            self.harvestInfo['requestHandler'] = 'grequests'
        if myconfig.tcp_connection_limit is not None and isinstance(myconfig.tcp_connection_limit, int):
            self.tcp_connection_limit = myconfig.tcp_connection_limit
            # generic in-house xslt to convert json-ld (xml) to rifcs
        if self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == "":
            self.harvestInfo['xsl_file'] = myconfig.run_dir + "resources/DataCite_Kernel4_To_Rifcs.xsl"

    def harvest(self):
        """
        the harvest method
        the usual set of procedures
        except we need to get a list of pages to extract the json-ld from
        get all content (in batches)
        save all content (in batches)
        run crosswalk after all content is received
        tell the registry the harvest is completed
        finish harvest
        """
        self.stopped = False
        self.setupdirs()
        self.setUpCrosswalk()
        self.updateHarvestRequest()
        self.logger.logMessage("DataCiteQueryHarvester Started")
        page_count = 1
        self.retrieveDOIMetadata(page_count)
        while self.recordCount > 0:
            page_count += 1
            self.retrieveDOIMetadata(page_count)
        self.setStatus("Generated %s File(s)" % str(page_count))
        self.logger.logMessage("Generated %s File(s)" % str(page_count))
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()


    def retrieveDOIMetadata(self, page_count):
        """
        retrieve individual DOI metadata with base64 encoded xml
        decode the XML and append it to the data
        """

        doiList = self.getDOIList(page_count)
        self.setStatus("Retrieving %s DOI(s)" % str(len(doiList)))
        for doi in doiList:
            self.logger.logMessage("getting datacite XML for %s" % doi)
            self.getDOIAsXML(doi)


    def getDOIAsXML(self, doi_id):
        try:
            url = myconfig.data_cite_api_url + '/dois/' + doi_id
            getRequest = Request(url)
            self.setStatus("HARVESTING", "Getting single DOI url:%s" %(url))
            self.logger.logMessage(
                "DATACITE QUERY (Retrieving Single DOI), getting data url:%s" %(url),
                "DEBUG")
            response = getRequest.getData()
            doi_metadata = json.loads(response, strict=False)
            base64xml = doi_metadata['data']['attributes']['xml']
            xml = base64.b64decode(base64xml)
            self.storeDOIMetadata(xml, doi_id.replace('/', '_'))
        except Exception as e:
            self.logger.logMessage(str(repr(e)), "ERROR")
            self.handleExceptions(e, terminate=False)


    def getDOIList(self, page_count):
        """
        use the SitemapCrawler to get all urls for a given site
        add all urls to the urlLinksList
        """
        doiList = []
        try:
            self.setStatus("Scanning Sitemap(s)")
            self.runDataciteQuery(page_count)
            data = json.loads(self.searchResults, strict=False)

            self.recordCount = len(data['data'])
            self.totalCount = data['meta']['total']
            for doi in data['data']:
                doiList.append(doi['id'])
            self.logger.logMessage("%s DOI(s) found" % str(self.recordCount), 'INFO')
        except Exception as e:
            self.logger.logMessage(str(repr(e)), "ERROR")
            self.handleExceptions(e, terminate=True)
        return doiList

    def runDataciteQuery(self, page_count):
        """
        gets a set of 400  DATACITE QUERY results in JSON format
        :return:
        """
        if self.stopped:
            return
        request_url = self.getRequestUrl(page_count)
        self.logger.logMessage("Reguest URL, %s" % request_url, "DEBUG")
        getRequest = Request(request_url)

        try:
            self.setStatus("HARVESTING", "Querying data url:%s" %(request_url))
            self.logger.logMessage(
                "DATACITE QUERY (Querying), getting data url:%s" %(request_url),
                "DEBUG")
            self.searchResults = getRequest.getData()
        except Exception as e:
                self.logger.logMessage("ERROR RECEIVING DATACITE QUERY RESULTS, %s" % str(repr(e)), "ERROR")
        del getRequest

    def getRequestUrl(self, pageCount):
        return self.harvestInfo['uri'] + "&page[size]=" + str(self.batchSize) + "&page[number]=" + str(pageCount)


    def storeDOIMetadata(self, xml, filename):
        """
        creates and XML and saves them to the given file in the harvested content directory
        """
        self.outputFilePath = self.outputDir + os.sep + filename + "." + self.storeFileExtension
        self.logger.logMessage("Harvester (storeHarvestData) %s " % (self.outputFilePath), "DEBUG")
        dataFile = open(self.outputFilePath, 'wb')
        self.setStatus("SAVING DOI XML", self.outputFilePath)
        dataFile.write(xml)
        dataFile.close()
        os.chmod(self.outputFilePath, 0o775)


    def runCrossWalk(self):
        """
        scan through the result contents and run an xslt transfor
        generic in-house xslt to convert DOI Metadata (xml) to rifcs unless the datasource harvest config sets an other XSLT
        :return:
        :rtype:
        """
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        self.logger.logMessage("runCrossWalk XSLT: %s" % self.harvestInfo['xsl_file'])
        self.logger.logMessage("OutDir: %s" % self.outputDir)
        for file in os.listdir(self.outputDir):
            if file.endswith(self.storeFileExtension):
                self.logger.logMessage("runCrossWalk %s" % file)
                outFile = self.outputDir + os.sep + file.replace(self.storeFileExtension, self.resultFileExtension)
                inFile = self.outputDir + os.sep + file
                try:
                    transformerConfig = {'xsl': self.harvestInfo['xsl_file'], 'outFile': outFile,
                                         'inFile': inFile}

                    tr = XSLT2Transformer(transformerConfig)
                    tr.transform()
                except subprocess.CalledProcessError as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " % (e.output.decode()), "ERROR")
                    msg = "'ERROR WHILE RUNNING CROSSWALK %s '" % (e.output.decode())
                    self.handleExceptions(msg)
                except Exception as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s" % (e), "ERROR")
                    self.handleExceptions(e)
