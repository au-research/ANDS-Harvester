import unittest
import myconfig
from harvest_handlers.PUREHarvester import PUREHarvester

import threading

class test_pure_harvester(unittest.TestCase):

    def not_test_uwa_pure(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://api.research-repository.uwa.edu.au/ws/api/511/datasets'
        harvestInfo['provider_type'] = 'PURE'
        harvestInfo['harvest_method'] = 'PURE'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'PURE-1'
        harvestInfo['harvest_id'] = '2'
        harvestInfo['batch_number'] = "BATCHNUMBER"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvestInfo['api_key'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    def not_test_bond_pure(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://pure.bond.edu.au/ws/api/513/datasets?apiKey=sjdhgkjsdhgksjdghskdjghs'
        harvestInfo['provider_type'] = 'PURE'
        harvestInfo['harvest_method'] = 'PURE'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'BOND'
        harvestInfo['harvest_id'] = '9'
        harvestInfo['batch_number'] = "BOND-BATCH"
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