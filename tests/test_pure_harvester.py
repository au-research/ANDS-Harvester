import unittest
import myconfig
from harvest_handlers.PUREHarvester import PUREHarvester

import threading

class test_pure_harvester(unittest.TestCase):

    def not_test_uwa_pure(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://api.research-repository.uwa.edu.au/ws/api/511/datasets?63cdba7a-e25e-4d2f-9692-2d4cc9bd9d97'
        harvestInfo['provider_type'] = 'PURE'
        harvestInfo['harvest_method'] = 'PURE'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'PURE-1'
        harvestInfo['harvest_id'] = '2'
        harvestInfo['batch_number'] = "BATCHNUMBER"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestInfo['api_key'] = "63cdba7a-e25e-4d2f-9692-2d4cc9bd9d97"  #UWA
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()

    def not_test_bond_pure(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://pure.bond.edu.au/ws/api/513/datasets?apiKey=00149b1a-1318-4994-85b7-a4de20105716'
        harvestInfo['provider_type'] = 'PURE'
        harvestInfo['harvest_method'] = 'PURE'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'BOND'
        harvestInfo['harvest_id'] = '9'
        harvestInfo['batch_number'] = "BOND-BATCH"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestInfo['api_key'] = "00149b1a-1318-4994-85b7-a4de20105716"  # UWA
        # harvestReq =   PUREHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PUREHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()