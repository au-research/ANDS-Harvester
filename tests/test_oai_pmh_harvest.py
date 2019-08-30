import unittest
import myconfig
from harvest_handlers.PMHHarvester import PMHHarvester
import io
from mock import patch
from utils.Request import Request

class test_oai_harvester(unittest.TestCase):

    def readfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/pmh/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_oai_pmh_harvest(self, mockGetData):
        mockGetData.side_effect = [
            self.readfile('Identify.xml'),
            self.readfile('1.xml'),
            self.readfile('2.xml')
        ]
        harvestInfo = {}
        harvestInfo['advanced_harvest_mode'] = "INCREMENTAL"
        harvestInfo['last_harvest_run_date'] = ''
        harvestInfo['batch_number'] = "PMH_DEAKIN"
        harvestInfo['data_source_id'] = 7
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



    def only_during_developement_test_oai_pmh_harvest_external(self):
        harvestInfo = {}
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['batch_number'] = "PMH_DEAKIN_LIVE"
        harvestInfo['data_source_id'] = 7
        harvestInfo['data_source_slug'] = "TEST"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "PMHHarvester"
        harvestInfo['mode'] = "TEST"
        harvestInfo['provider_type'] = 'rif'
        harvestInfo['response_url'] = ""
        harvestInfo['title'] = "TEST"
        harvestInfo['uri'] = "http://dro.deakin.edu.au/oai.php"
        harvestInfo['xsl_file'] = ""
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = PMHHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()