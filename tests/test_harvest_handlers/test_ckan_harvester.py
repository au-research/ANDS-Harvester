import unittest
import myconfig
from harvest_handlers.CKANHarvester import CKANHarvester
import io
from mock import patch
from utils.Request import Request
import threading

class test_ckan_harvester(unittest.TestCase):

    def readfile(self, path):
        f = io.open(myconfig.run_dir + 'tests/resources/test_source/ckan/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_ckan_package_list(self, mockGetData):
        mockGetData.side_effect = [
            self.readfile('package_list.json'),
            self.readfile('package_show_1.json'),
            self.readfile('package_show_2.json'),
            self.readfile('package_show_3.json'),
            self.readfile('package_show_4.json'),
            self.readfile('package_show_5.json'),
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'CKAN'
        harvestInfo['harvest_method'] = 'CKAN'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "CKAN_DATA2_CERDI"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANHarvester(harvestInfo)
        harvester.harvest()


    def only_during_developement_test_ckan_package_list_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://data2.cerdi.edu.au/'
        harvestInfo['provider_type'] = 'CKAN'
        harvestInfo['harvest_method'] = 'CKAN'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "CKAN_DATA2_CREDI__LIVE"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()

