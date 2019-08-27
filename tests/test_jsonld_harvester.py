import unittest
import myconfig
from harvest_handlers.JSONLDHarvester import JSONLDHarvester

import threading

class test_jsonld_harvester(unittest.TestCase):

    def not_test_small_text_site_map(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/small-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "small_text_site_map"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "TEST"
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def not_test_small_crosswalk(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/small-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "small_crosswalk"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.crosswalk()

    def not_test_text_site_map(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/auscope-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "test_text_site_map"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        #harvestReq = JSONLDHarvester(harvestInfo)
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()


    def not_test_aurin_site_map(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://demo.ands.org.au/aurin-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "test_aurin_site_map"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def not_test_xml_site_map_earthcube(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://demo.ands.org.au/home/sitemap/?ds=1'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = '7'
        harvestInfo['harvest_id'] = '1'
        harvestInfo['batch_number'] = "xml_site_map_earthcube"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()


if __name__ == '__main__':
    unittest.main()