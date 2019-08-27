import unittest
import myconfig
from harvest_handlers.GETHarvester import GETHarvester

import threading

class test_get_harvester(unittest.TestCase):

    def not_test_XML_get(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://devl.ands.org.au/leo/UniSA_reimport280817.xml'
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'GET-1'
        harvestInfo['harvest_id'] = '5'
        harvestInfo['batch_number'] = "GET_XML"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "HARVEST"
        harvestInfo['api_key'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()

    def not_test_JSON_get(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://data.gov.au/api/3/action/package_search?fq=((*:*%20NOT%20harvest_source_id:*)%20AND%20(type:dataset))'
        harvestInfo['provider_type'] = 'GET'
        harvestInfo['harvest_method'] = 'GET'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 'GET-1'
        harvestInfo['harvest_id'] = '5'
        harvestInfo['batch_number'] = "GET_JSON"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "HARVEST"
        harvestInfo['api_key'] = myconfig.uwa_api_key
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = GETHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()