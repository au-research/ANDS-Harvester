import unittest
import myconfig
from harvest_handlers.CKANHarvester import CKANHarvester

import threading

class test_get_harvester(unittest.TestCase):

    def not_test_ckan_package_list(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://data2.cerdi.edu.au/'
        harvestInfo['provider_type'] = 'CKAN'
        harvestInfo['harvest_method'] = 'CKAN'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "CKAN-TEST"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANHarvester(harvestInfo)
        harvester.harvest()



if __name__ == '__main__':
    unittest.main()

