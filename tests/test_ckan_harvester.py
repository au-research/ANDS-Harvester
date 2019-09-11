import unittest
import myconfig
from harvest_handlers.CKANHarvester import CKANHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading

class test_ckan_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/ckan/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_ckan_package_list(self, mockGetData):
        batch_id = "CKAN_DATA2_CERDI"
        ds_id = 5
        mockGetData.side_effect = [
            self.readTestfile('package_list.json'),
            self.readTestfile('package_show_1.json'),
            self.readTestfile('package_show_2.json'),
            self.readTestfile('package_show_3.json'),
            self.readTestfile('package_show_4.json'),
            self.readTestfile('package_show_5.json'),
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'CKAN'
        harvestInfo['harvest_method'] = 'CKAN'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/odapi2rif.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<collection type="dataset">', content)
        content = self.readFile(tempFile)
        self.assertIn('<private>False</private>', content)

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
        harvestInfo['xsl_file'] = "resources/odapi2rif.xsl"
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()

