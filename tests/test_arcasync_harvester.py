import unittest
import myconfig
from harvest_handlers.ARCAsyncHarvester import ARCAsyncHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading
import time
class test_arcasync_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/arcasync/' + path, mode="r")
        data = f.read()
        f.close()
        return data


    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def not_yet_test_small_getGrantList(self, mockGetData):
        batch_id = "ARCAsync_1"
        ds_id = 33
        mockGetData.side_effect = [
            self.readTestfile('grants.json'),
            self.readTestfile('LP190100083.json'),
            self.readTestfile('LP190100294.json'),
            self.readTestfile('LP190100551.json'),
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'ARCAsync'
        harvestInfo['harvest_method'] = 'ARCAsync'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/ARCAPI_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        harvestInfo['requestHandler'] = "basic"
        harvestInfo['title'] = "The Australian Research Council Grants"
        harvester = ARCAsyncHarvester(harvestInfo)
        harvester.setbatchSize(3)
        harvester.harvest()
        jsonFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.json"
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.xml"
        self.assertTrue(os.path.exists(jsonFile))
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<identifier type="local">LP190100083</identifier>', content)
        content = self.readFile(tempFile)
        self.assertIn('<grant uri="https://dataportal.arc.gov.au/NCGP/API/grants/LP190100083">', content)

    @patch.object(Request, 'getData')
    def not_yet_test_text_site_map_combined_files(self, mockGetData):
        batch_id = "ARCAsync_2"
        ds_id = 33
        mockGetData.side_effect = [
            self.readTestfile('grants.json'),
            self.readTestfile('LP190100083.json'),
            self.readTestfile('LP190100294.json'),
            self.readTestfile('LP190100551.json'),
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'ARCAsync'
        harvestInfo['harvest_method'] = 'ARCAsync'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/ARCAPI_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "TEST"
        harvestInfo['requestHandler'] = "basic"
        harvestInfo['title'] = "The Datasource Title"
        harvester = ARCAsyncHarvester(harvestInfo)
        harvester.setbatchSize(1)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined_1.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined_1.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<identifier type="local">LP190100083</identifier>', content)
        content = self.readFile(tempFile)
        self.assertIn('<grant uri="https://dataportal.arc.gov.au/NCGP/API/grants/LP190100083">', content)


    def only_during_development_test_thread_safe_crawl(self):
        batch_id_1 = "ARCAsync_T1"
        ds_id_1 = 333
        harvestInfo_1 = {}
        harvestInfo_1['uri'] = 'https://dataportal.arc.gov.au/NCGP/API/grants/'
        harvestInfo_1['provider_type'] = 'ARCAsync'
        harvestInfo_1['harvest_method'] = 'ARCAsync'
        harvestInfo_1['data_store_path'] = myconfig.data_store_path
        harvestInfo_1['response_url'] = myconfig.response_url
        harvestInfo_1['data_source_id'] = ds_id_1
        harvestInfo_1['harvest_id'] = 1
        harvestInfo_1['batch_number'] = batch_id_1
        harvestInfo_1['advanced_harvest_mode'] = "STANDARD"
        harvestInfo_1['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/ARCAPI_json_to_rif-cs.xsl"
        harvestInfo_1['mode'] = "TEST"
        harvestInfo_1['requestHandler'] = "grequests"
        harvestInfo_1['title'] = "The Datasource Title"

        batch_id_2 = "ARCASync_T2"
        ds_id_2 = 9
        harvestInfo_2 = {}
        harvestInfo_2['uri'] = 'https://dataportal.arc.gov.au/NCGP/API/grants/'
        harvestInfo_2['provider_type'] = 'ARCAsync'
        harvestInfo_2['harvest_method'] = 'ARCAsync'
        harvestInfo_2['data_store_path'] = myconfig.data_store_path
        harvestInfo_2['response_url'] = myconfig.response_url
        harvestInfo_2['data_source_id'] = ds_id_2
        harvestInfo_2['harvest_id'] = 9
        harvestInfo_2['batch_number'] = batch_id_2
        harvestInfo_2['advanced_harvest_mode'] = "STANDARD"
        harvestInfo_2['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/ARCAPI_json_to_rif-cs.xsl"
        harvestInfo_2['mode'] = "TEST"
        harvestInfo_2['requestHandler'] = "grequests"
        harvestInfo_2['title'] = "The Datasource Title"
        # basic or asyncio
        harvestReq_1 = ARCAsyncHarvester(harvestInfo_1)
        harvestReq_1.setbatchSize(1)
        t_1 = threading.Thread(name="one", target=harvestReq_1.harvest)
        t_1.start()

        harvestReq_2 = ARCAsyncHarvester(harvestInfo_2)
        harvestReq_1.setbatchSize(1)
        t_2 = threading.Thread(name="two", target=harvestReq_2.harvest)
        t_2.start()
        both_running = True
        while both_running:
            both_running = t_1.isAlive() or t_2.isAlive()
            time.sleep(1)

        resultFile_1 = myconfig.data_store_path + str(ds_id_1) + os.sep + batch_id_1 + os.sep + "combined_1.tmp"
        resultFile_2 = myconfig.data_store_path + str(ds_id_2) + os.sep + batch_id_2 + os.sep + "combined_1.tmp"
        self.assertTrue(os.path.exists(resultFile_1))
        self.assertTrue(os.path.exists(resultFile_2))

    def test_mockoon_endpoint(self):
        batch_id = "ARCAsync_4"
        ds_id = 33
        harvestInfo = {}
        harvestInfo['uri'] = 'https://mock.test.ardc.edu.au/NCGP/API/grants/'
        harvestInfo['provider_type'] = 'ARCAsync'
        harvestInfo['harvest_method'] = 'ARCAsync'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/ARCAPI_json_to_rif-cs.xsl"
        harvestInfo['mode'] = "HARVEST"
        harvestInfo['requestHandler'] = "grequests"
        harvestInfo['title'] = "The Datasource Title"
        harvester = ARCAsyncHarvester(harvestInfo)
        harvester.harvest()
        resultFile_1 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.tmp"
        resultFile_2 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.xml"
        self.assertTrue(os.path.exists(resultFile_1))
        self.assertTrue(os.path.exists(resultFile_2))


    def fun_test_instance_vs_class_variables(self):
        harvestInfo = {}
        harvestInfo['mode'] = "TEST"
        harvestInfo['xsl_file'] = ""
        harvestInfo['title'] = "The Datasource Title"
        harvester_1 = ARCAsyncHarvester(harvestInfo)
        harvester_2 = ARCAsyncHarvester(harvestInfo)

        #unitialised class primitive variables can be set at instance level
        print(harvester_1.getbatchSize())
        harvester_1.setbatchSize(50)
        print(harvester_2.getbatchSize())
        harvester_2.setbatchSize(20)
        print(harvester_1.getbatchSize())
        print(harvester_2.getbatchSize())

        # unitialised class variables eg list or dict are shared by instances
        # uncomment self.testList = [] in the constructor to see the difference
        harvester_1.addItemtoTestList("one stuff")
        harvester_2.addItemtoTestList("two stuff")
        harvester_2.addItemtoTestList("two more stuff")
        harvester_1.addItemtoTestList("one more stuff")
        harvester_2.addItemtoTestList("two more more stuff")
        harvester_1.printTestList()
        print("\n")
        harvester_2.printTestList()


if __name__ == '__main__':
    unittest.main()