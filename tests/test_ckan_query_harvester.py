import unittest
import myconfig
from harvest_handlers.CKANQUERYHarvester import CKANQUERYHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading

class test_ckan_query_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/ckan_query/' + path, mode="r")
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
        batch_id = "CKAN_DATA_QUERY"
        ds_id = 8
        mockGetData.side_effect = [
            self.readTestfile('package_0.json'),
            self.readTestfile('package_1.json'),
            self.readTestfile('package_2.json'),
            self.readTestfile('package_3.json'),
            self.readTestfile('package_4.json'),
            self.readTestfile('package_5.json'),
        ]
        harvestInfo = {}
        harvestInfo['uri'] = 'https://ckan.publishing.service.gov.uk/api/action/package_search?fq=(type:dataset)'
        harvestInfo['provider_type'] = 'CKAN'
        harvestInfo['harvest_method'] = 'CKAN'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "tests/resources/xslt/data.gov.au_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANQUERYHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<key>FD60E2DF-678A-46FE-A189-121F83F30428</key>', content)
        content = self.readFile(tempFile)
        self.assertIn('<value>FD60E2DF-678A-46FE-A189-121F83F30428</value>', content)

    def only_during_development_test_retry_count(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://ckan.publis.service.govy'
        harvestInfo['provider_type'] = 'CKANQUERY'
        harvestInfo['harvest_method'] = 'CKANQUERY'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '8'
        harvestInfo['harvest_id'] = '6'
        harvestInfo['batch_number'] = "CKAN_DATA_GOV_UK"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "tests/resources/xslt/data.gov.au_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANQUERYHarvester(harvestInfo)
        harvester.harvest()


    def only_during_development_test_ckan_package_list_external(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://data.gov.au/api/3/action/package_search?fq=((*:*%20NOT%20harvest_source_id:*)%20AND%20(type:dataset))'
        harvestInfo['provider_type'] = 'CKANQUERY'
        harvestInfo['harvest_method'] = 'CKANQUERY'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '8'
        harvestInfo['harvest_id'] = '6'
        harvestInfo['batch_number'] = "CKAN_DATA_GOV_UK"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "tests/resources/xslt/data.gov.au_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CKANQUERYHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()

