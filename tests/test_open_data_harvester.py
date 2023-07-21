import unittest
import myconfig
from harvest_handlers.OPENDATAHarvester import OPENDATAHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading

class test_open_data_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/open_data/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_open_data(self, mockGetData):
        batch_id = "OPEN_DATA"
        ds_id = 7
        mockGetData.side_effect = [
            self.readTestfile('page_0.json'),
            self.readTestfile('page_1.json'),
            self.readTestfile('page_2.json'),
            self.readTestfile('page_3.json'),
            self.readTestfile('page_4.json'),
            self.readTestfile('empty_page.json')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = 'https://www.data.act.gov.au/api/views/metadata/v1'
        harvestInfo['provider_type'] = 'OPENDATA'
        harvestInfo['harvest_method'] = 'OPENDATA'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['title'] = "The Title of the datasource"
        harvestInfo['harvest_id'] = 9
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/open_data_to_rifcs.xsl"
        harvestInfo['mode'] = "TEST"

        harvester = OPENDATAHarvester(harvestInfo)
        harvester.setRows(10)
        harvester.harvest()
        srcFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.json"
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(srcFile))
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(srcFile)
        self.assertIn('"id": "xvid-q4du"', content)
        content = self.readFile(tempFile)
        self.assertIn('<id>47ij-ew9u</id>', content)
        content = self.readFile(resultFile)
        self.assertIn('<key>xvid-q4du</key>', content)



    def only_when_developing_test_open_data_live(self):
        batch_id = "OPENDATA_DATA_ACT_GOV"
        ds_id = 7
        harvestInfo = {}
        harvestInfo['uri'] = 'https://www.data.act.gov.au/api/views/metadata/v1'
        harvestInfo['provider_type'] = 'OPENDATA'
        harvestInfo['harvest_method'] = 'OPENDATA'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['title'] = "The Title of the datasource"
        harvestInfo['harvest_id'] = '9'
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/open_data_to_rifcs.xsl"
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = OPENDATAHarvester(harvestInfo)
        harvester.harvest()
        srcFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.json"
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        self.assertTrue(os.path.exists(srcFile))
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(srcFile)
        self.assertIn('"id": "xvid-q4du"', content)
        content = self.readFile(tempFile)
        self.assertIn('<id>xvid-q4du</id>', content)
        content = self.readFile(resultFile)
        self.assertIn('<key>xvid-q4du</key>', content)


if __name__ == '__main__':
    unittest.main()

