import unittest
import myconfig
from harvest_handlers.PUREHarvester import PUREHarvester
import io
from mock import patch
from utils.Request import Request

class test_pure_harvester(unittest.TestCase):


    def readfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/pure/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_uwa_pure(self, mockGetData):
        mockGetData.side_effect = [
            self.readfile('page_1.xml'),
            self.readfile('page_2.xml'),
            self.readfile('page_3.xml'),
            self.readfile('page_4.xml'),
            self.readfile('page_5.xml')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "PURE_UWA"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvestInfo['api_key'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    # API KEYS PROVIDED BY Melanie (for testing)
    def only_during_developement_test_uwa_pure_external(self):
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
        harvestInfo['api_key'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    # API KEYS PROVIDED BY Melanie (for testing)
    def only_during_developement_test_bond_pure_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://pure.bond.edu.au/ws/api/513/datasets?apiKey=sjdhgkjsdhgksjdghskdjghs'
        harvestInfo['harvest_method'] = 'PUREHarvester'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "PURE_BOND_LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvestInfo['api_key'] = myconfig.bond_api_key
        # harvestReq =   PUREHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()