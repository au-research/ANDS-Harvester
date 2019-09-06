import unittest
import myconfig
from harvest_handlers.GETHarvester import GETHarvester
from mock import patch
from utils.Request import Request
import threading, io, os

class test_get_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/get/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_XML_get(self, mockGetData):
        batch_id = "GET_XML"
        ds_id = 6
        mockGetData.return_value = self.readTestfile('data_act_gov.xml')
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 2
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/odapi2rif.xsl"
        harvestInfo['mode'] = "HARVEST"
        #harvestReq = GETHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()

        harvester = GETHarvester(harvestInfo)
        harvester.harvest()
        # tests
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<collection type="Dataset">', content)
        content = self.readFile(tempFile)
        self.assertIn('<distribution>', content)

    @patch.object(Request, 'getData')
    def test_JSON_get(self, mockGetData):
        batch_id = "GET_JSON"
        ds_id = 6
        mockGetData.return_value = self.readTestfile('get_json.json')
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 2
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/odapi2rif.xsl"
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()

        # tests
        jsonFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.json"
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        print(jsonFile)
        self.assertTrue(os.path.exists(jsonFile))
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))

        content = self.readFile(jsonFile)
        self.assertIn('"@context": "https://project-open-data.cio.gov/v1.1/schema/catalog.jsonld"', content)

        content = self.readFile(resultFile)
        self.assertIn('<collection type="Dataset">', content)

        content = self.readFile(tempFile)
        self.assertIn('<distribution>', content)


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