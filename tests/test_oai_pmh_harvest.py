import unittest
import myconfig
from harvest_handlers.PMHHarvester import PMHHarvester
import io, os
from mock import patch
from utils.Request import Request

class test_oai_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/pmh/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data


    @patch.object(Request, 'getData')
    def test_oai_pmh_harvest(self, mockGetData):
        batch_id = "PMH_DEAKIN"
        ds_id = 2
        mockGetData.side_effect = [
            self.readTestfile('Identify.xml'),
            self.readTestfile('1.xml'),
            self.readTestfile('2.xml')
        ]
        harvestInfo = {}
        harvestInfo['advanced_harvest_mode'] = "INCREMENTAL"
        harvestInfo['last_harvest_run_date'] = ''
        harvestInfo['batch_number'] = batch_id
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['data_source_slug'] = "TEST"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "PMHHarvester"
        harvestInfo['mode'] = "TEST"
        harvestInfo['provider_type'] = 'rif'
        harvestInfo['response_url'] = ""
        harvestInfo['title'] = "TEST"
        harvestInfo['uri'] = ""
        harvestInfo['xsl_file'] = ""
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PMHHarvester(harvestInfo)
        harvester.harvest()

        file1 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        file2 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "2.xml"
        self.assertTrue(os.path.exists(file1))
        self.assertTrue(os.path.exists(file2))


    def only_during_dev_chunked_oai_pmh_harvest_external(self):
        harvestInfo = {}
        batch_id = "PMH_ESPACE_LIVE"
        ds_id = 2
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['batch_number'] = batch_id
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['data_source_slug'] = "TEST"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "PMHHarvester"
        harvestInfo['mode'] = "TEST"
        harvestInfo['provider_type'] = 'rif'
        harvestInfo['response_url'] = ""
        harvestInfo['title'] = "HARVEST"
        harvestInfo['uri'] = "https://espace.library.uq.edu.au/oai.php"
        harvestInfo['xsl_file'] = ""
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PMHHarvester(harvestInfo)
        harvester.harvest()
        file1 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.xml"
        file2 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "2.xml"
        self.assertTrue(os.path.exists(file1))
        self.assertTrue(os.path.exists(file2))



    def test_igsn_records_harvester_for_migration(self):
        """
        This "test" is used to harvest all production IGSN records for the IGSN 2040 sprint in May 2020
        :return:
        :rtype:
        """
        harvestInfo = {}
        batch_id = "PMH_IGSN_PROD"
        ds_id = 11
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['batch_number'] = batch_id
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['data_source_slug'] = "TEST"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "PMHHarvester"
        harvestInfo['mode'] = "HARVEST"
        harvestInfo['provider_type'] = 'cs_igsn'
        harvestInfo['response_url'] = ""
        harvestInfo['title'] = "HARVEST"
        harvestInfo['uri'] = "https://identifiers.ardc.edu.au/igsn/api/service/30/oai"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/resources/xslt/igsn-oai.xsl"
        harvester = PMHHarvester(harvestInfo)

        harvester.harvest()
        file1 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "1.tmp"
        file2 = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "2.tmp"
        self.assertTrue(os.path.exists(file1))
        self.assertTrue(os.path.exists(file2))

if __name__ == '__main__':
    unittest.main()