import unittest
import myconfig
from harvest_handlers.JSONLDHarvester import JSONLDHarvester
import io, os
from mock import patch
from utils.Request import Request

class test_jsonld_harvester(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/jsonld/' + path, mode="r")
        data = f.read()
        f.close()
        return data


    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data


    # @patch.object(Request, 'getData')
    # def test_xml_site_map(self, mockGetData):
    #     mockGetData.side_effect = []
    #     mockGetData.side_effect = [
    #         self.readTestfile('sitemap.xml'),
    #         self.readTestfile('urlset.xml'),
    #         self.readTestfile('urlset_2.xml'),
    #         self.readTestfile('page_1.html'),
    #         self.readTestfile('page_2.html'),
    #         self.readTestfile('page_3.html'),
    #         self.readTestfile('page_4.html'),
    #         self.readTestfile('page_5.html'),
    #         self.readTestfile('page_6.html'),
    #         self.readTestfile('page_7.html'),
    #         self.readTestfile('page_8.html'),
    #         self.readTestfile('page_9.html'),
    #         self.readTestfile('page_10.html')
    #     ]
    #     harvestInfo = {}
    #     harvestInfo['uri'] = ''
    #     harvestInfo['provider_type'] = 'JSONLD'
    #     harvestInfo['harvest_method'] = 'JSONLD'
    #     harvestInfo['data_store_path'] = myconfig.data_store_path
    #     harvestInfo['response_url'] = myconfig.response_url
    #     harvestInfo['data_source_id'] = 7
    #     harvestInfo['harvest_id'] = 1
    #     harvestInfo['batch_number'] = "JSONLD_1"
    #     harvestInfo['advanced_harvest_mode'] = "STANDARD"
    #     harvestInfo['xsl_file'] = myconfig.run_dir + "resources/schemadotorg2rif.xsl"
    #     harvestInfo['mode'] = "TEST"
    #     #harvestReq = JSONLDHarvester(harvestInfo)
    #     #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
    #     #t.start()
    #     harvester = JSONLDHarvester(harvestInfo)
    #     harvester.harvest()


    @patch.object(Request, 'getData')
    def test_text_site_map(self, mockGetData):
        batch_id = "JSONLD_1"
        ds_id = 3
        mockGetData.side_effect = [
            self.readTestfile('sitemap.txt'),
            self.readTestfile('page_1.html'),
            self.readTestfile('page_2.html'),
            self.readTestfile('page_3.html'),
            self.readTestfile('page_4.html'),
            self.readTestfile('page_5.html'),
            self.readTestfile('page_6.html'),
            self.readTestfile('page_7.html'),
            self.readTestfile('page_8.html'),
            self.readTestfile('page_9.html'),
            self.readTestfile('page_10.html')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "TEST"
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('<description type="brief">Mineral Saturation Index</description>', content)
        content = self.readFile(tempFile)
        self.assertIn('<datasets><dataset><context>http://schema.org/</context>', content)

    @patch.object(Request, 'getData')
    def only_during_developement_test_urlset_map(self, mockGetData):
        mockGetData.side_effect = [
            self.readTestfile('urlset.xml'),
            self.readTestfile('page_1.html'),
            self.readTestfile('page_2.html'),
            self.readTestfile('page_3.html'),
            self.readTestfile('page_4.html'),
            self.readTestfile('page_5.html')
        ]
        harvestInfo = {}
        harvestInfo['uri'] = ''
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_2"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.crosswalk()

    def only_during_developement_test_small_text_site_map_1(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/small-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_1"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "TEST"
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def only_during_developement_test_small_crosswalk_2(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/small-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_2"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo['mode'] = "HARVEST"
        # harvestReq = JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.crosswalk()

    def only_during_developement_test_text_site_map_3(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'http://demo.ands.org.au/auscope-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_3"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        #harvestReq = JSONLDHarvester(harvestInfo)
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()


    def only_during_developement_test_aurin_site_map_4(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://demo.ands.org.au/aurin-sitemap.txt'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_4"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def only_during_developement_test_xml_site_map_earthcube_5(self):
        harvestInfo = {}
        harvestInfo['uri'] = 'https://demo.ands.org.au/home/sitemap/?ds=1'
        harvestInfo['provider_type'] = 'JSONLD'
        harvestInfo['harvest_method'] = 'JSONLD'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = 7
        harvestInfo['harvest_id'] = 1
        harvestInfo['batch_number'] = "JSONLD_5"
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = ""
        harvestInfo['mode'] = "TEST"
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

if __name__ == '__main__':
    unittest.main()