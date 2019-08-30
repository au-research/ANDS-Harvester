import unittest
import myconfig
from harvest_handlers.CSWHarvester import CSWHarvester
import io
from mock import patch
from utils.Request import Request


class test_csw_harvester(unittest.TestCase):

    def readfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/csw/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    @patch.object(Request, 'getData')
    def test_csw_harvest(self, mockGetData):
        mockGetData.return_value = self.readfile('tern_csw.xml')
        harvestInfo = {}
        harvestInfo['advanced_harvest_mode'] = "REFRESH"
        harvestInfo['batch_number'] = "CSW_TERN"
        harvestInfo['data_source_id'] = 7
        harvestInfo['data_source_slug'] = "TERN-Geonetwork"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "CSWHarvester"
        harvestInfo['mode'] = "TEST"
        harvestInfo['provider_type'] = 'http://www.isotc211.org/2005/gmd'
        harvestInfo['response_url'] = "http://localhost/api/import"
        harvestInfo['title'] = "TERN Geonetwork"
        harvestInfo['uri'] = ''
        harvestInfo['user_defined_params'] = '[{"name":"request","value":"GetRecords"},{"name":"service","value":"CSW"},{"name":"version","value":"2.0.2"},{"name":"namespace","value":"xmlns(csw=http://www.opengis.net/cat/csw)"},{"name":"resultType","value":"results"},{"name":"outputFormat","value":"application/xml"},{"name":"typeNames","value":"csw:Record"},{"name":"elementSetName","value":"full"},{"name":"constraintLanguage","value":"CQL_TEXT"},{"name":"constraint_language_version","value":"1.1.0v"}]'
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/TERN_ISO19139_rif.xsl"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CSWHarvester(harvestInfo)
        harvester.harvest()


    def only_during_developement_test_csw_harvest_external(self):
        harvestInfo = {}
        harvestInfo['advanced_harvest_mode'] = "REFRESH"
        harvestInfo['batch_number'] = "CSW_TERN_LIVE"
        harvestInfo['data_source_id'] = 7
        harvestInfo['data_source_slug'] = "TERN-Geonetwork"
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = 1
        harvestInfo['harvest_method'] = "CSWHarvester"
        harvestInfo['mode'] = "HARVEST"
        harvestInfo['provider_type'] = 'http://www.isotc211.org/2005/gmd'
        harvestInfo['response_url'] = "http://localhost/api/import"
        harvestInfo['title'] = "TERN Geonetwork"
        harvestInfo['uri'] = "http://geonetwork.tern.org.au/geonetwork/srv/eng/csw"
        harvestInfo['user_defined_params'] = '[{"name":"request","value":"GetRecords"},{"name":"service","value":"CSW"},{"name":"version","value":"2.0.2"},{"name":"namespace","value":"xmlns(csw=http://www.opengis.net/cat/csw)"},{"name":"resultType","value":"results"},{"name":"outputFormat","value":"application/xml"},{"name":"typeNames","value":"csw:Record"},{"name":"elementSetName","value":"full"},{"name":"constraintLanguage","value":"CQL_TEXT"},{"name":"constraint_language_version","value":"1.1.0v"}]'
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/TERN_ISO19139_rif.xsl"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = CSWHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()


