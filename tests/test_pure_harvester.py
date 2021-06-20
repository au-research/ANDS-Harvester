import unittest
import myconfig
from harvest_handlers.PUREHarvester import PUREHarvester
import io, os
from mock import patch
from utils.Request import Request

class test_pure_harvester(unittest.TestCase):


    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/pure/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_uwa_pure(self, mockGetData):
        batch_id = "PURE_UWA"
        ds_id = 1
        mockGetData.side_effect = [
            self.readTestfile('page_1.xml'),
            self.readTestfile('page_2.xml'),
            self.readTestfile('page_3.xml'),
            self.readTestfile('page_4.xml'),
            self.readTestfile('page_5.xml')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/Elsevier_PURE_Params.xsl"
        harvestInfo['mode'] = "TEST"
        harvestInfo['apiKey'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(tempFile)
        self.assertIn('<doi>10.4225/57/5b29e9c09280e</doi>', content)
        content = self.readFile(resultFile)
        self.assertIn('<identifier type="doi">http://doi.org/10.4225/57/5b29e9c09280e</identifier>', content)

    @patch.object(Request, 'getData')
    def test_uwa_pure_crosswalk_only(self, mockGetData):
        batch_id = "PURE_UWA"
        ds_id = 1
        mockGetData.side_effect = [
            self.readTestfile('page_1.xml'),
            self.readTestfile('page_2.xml'),
            self.readTestfile('page_3.xml'),
            self.readTestfile('page_4.xml'),
            self.readTestfile('page_5.xml')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/Elsevier_PURE_Params.xsl"
        harvestInfo['mode'] = "TEST"
        harvestInfo['apiKey'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.crosswalk()
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(tempFile)
        self.assertIn('<doi>10.4225/57/5b29e9c09280e</doi>', content)
        content = self.readFile(resultFile)
        self.assertIn('<identifier type="doi">http://doi.org/10.4225/57/5b29e9c09280e</identifier>', content)

    # API KEYS PROVIDED BY Melanie (for testing)
    def only_during_development_test_uwa_pure_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://api.research-repository.uwa.edu.au/ws/api/511/datasets'
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "PURE_UWA_LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvestInfo['apiKey'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    # API KEYS PROVIDED BY Melanie (for testing)
    def only_during_development_test_bond_pure_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://pure.bond.edu.au/ws/api/517/datasets?apiKey=00149b1a-1318-4994-85b7-a4de20105716'
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "PURE_BOND_LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"

        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    def only_during_development_test_bond_pure_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://api.research-repository.uwa.edu.au/ws/api/517/equipments?apiKey=63cdba7a-e25e-4d2f-9692-2d4cc9bd9d97'
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "PURE_UWA_EQUIP"
        harvestInfo['xsl_file'] = ''
        print(myconfig.abs_path)
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['mode'] = "TEST"
        harvestInfo['apiKey'] = myconfig.uwa_api_key

        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()



if __name__ == '__main__':
    unittest.main()