import unittest
import myconfig
from harvest_handlers.MAGDAQUERYHarvester import MAGDAQUERYHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading

class test_magda_query_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/magda/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_magda_query(self, mockGetData):
        batch_id = "MAGDA"
        ds_id = 9
        mockGetData.side_effect = [
            self.readTestfile('1.json'),
            self.readTestfile('2.json'),
            self.readTestfile('3.json'),
            self.readTestfile('4.json'),
            self.readTestfile('5.json')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = 'https://data.gov.au/api/v0/search/datasets?publisher=Bioregional%20Assessment%20Programme'
        harvestInfo['provider_type'] = 'MAGDAQUERY'
        harvestInfo['harvest_method'] = 'MAGDAQUERY'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 7
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "tests/resources/xslt/data.gov.au.magda_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = MAGDAQUERYHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<key>ds-dga-806c3770-031e-41da-99cd-9fe79f237050</key>', content)
        content = self.readFile(tempFile)
        self.assertIn('<identifier>ds-dga-806c3770-031e-41da-99cd-9fe79f237050</identifier>', content)


    def only_during_development_test_retry_count(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://data.gov.au/api/v0/search/datasets?publisher=Bioregional%20Assessment%20Programme'
        harvestInfo['provider_type'] = 'MAGDAQUERY'
        harvestInfo['harvest_method'] = 'MAGDAQUERY'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '9'
        harvestInfo['harvest_id'] = '7'
        harvestInfo['batch_number'] = "MAGDA_SOLR_DATA_GOV"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "tests/resources/xslt/data.gov.au.magda_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = MAGDAQUERYHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()

