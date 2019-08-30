import unittest
import myconfig
from harvest_handlers.GETHarvester import GETHarvester
from mock import patch
from utils.Request import Request
import threading, io

class test_get_harvester(unittest.TestCase):

    def readfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/get/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_XML_get(self, mockGetData):
        mockGetData.return_value = self.readfile('get_xml.xml')
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "GET_XML"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        #harvestReq = GETHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()

    @patch.object(Request, 'getData')
    def test_JSON_get(self, mockGetData):
        mockGetData.return_value = self.readfile('get_json.json')
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "GET_JSON"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()


    def only_during_developement_test_XML_get_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://devl.ands.org.au/leo/UniSA_reimport280817.xml'
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "GET_XML_LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()

    def only_during_developement_test_JSON_get_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://data.gov.au/api/3/action/package_search?fq=((*:*%20NOT%20harvest_source_id:*)%20AND%20(type:dataset))'
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "GET_JSON_LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()