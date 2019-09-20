import unittest
import myconfig
from harvest_handlers.JSONLDHarvester import JSONLDHarvester
import io, os
from mock import patch
from utils.Request import Request
import threading
import time
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
        harvestInfo['requestHandler'] = "basic"
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.xml"
        #rdfFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.rdf"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        #self.assertTrue(os.path.exists(rdfFile))
        content = self.readFile(resultFile)
        self.assertIn('<description type="brief">Water Sampling</description>', content)
        content = self.readFile(tempFile)
        self.assertIn('<spatialCoverage><type>Place</type><geo><type>GeoShape</type><box>-29.06762 115.45924 -23.366095 122.62305</box></geo></spatialCoverage>', content)
        #content = self.readFile(rdfFile)
        #self.assertIn('<box>-29.06762 115.45924 -24.71488 122.62305</box>', content)

    @patch.object(Request, 'getData')
    def test_text_site_map_combined_files(self, mockGetData):
        batch_id = "JSONLD_2"
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
        harvestInfo['requestHandler'] = "basic"
        # harvestReq = JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.xml"
        #rdfFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "combined.rdf"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        #self.assertTrue(os.path.exists(rdfFile))
        content = self.readFile(resultFile)
        self.assertIn('<key>https://demo.ands.org.au/mineral-occurrence-portrayal-australia-10/817266</key>', content)
        content = self.readFile(tempFile)
        self.assertIn('<name>EarthResourceML mining feature occurrences of Northern Territory of Australia</name>', content)
        #content = self.readFile(rdfFile)
        #self.assertIn('<rdf:Description rdf:about="doi:10.1594/IEDA/111278">', content)


    def only_during_development_test_small_text_site_map_1(self):
        batch_id = "JSONLD_3"
        ds_id = 3
        harvestInfo = {}
        harvestInfo['uri'] = 'http://opencoredata.org/sitemap.xml'
        #harvestInfo['uri'] = 'http://demo.ands.org.au/auscope-sitemap.txt'
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
        harvestInfo['requestHandler'] = "grequests"
        # basic or asyncio
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def only_during_development_test_thread_safe_crawl(self):
        batch_id_1 = "JSONLD_T1"
        ds_id_1 = 8
        harvestInfo_1 = {}
        harvestInfo_1['uri'] = 'file:///' + myconfig.abs_path + '/tests/resources/test_source/jsonld/thread_test_sitemap_1.xml'
        harvestInfo_1['provider_type'] = 'JSONLD'
        harvestInfo_1['harvest_method'] = 'JSONLD'
        harvestInfo_1['data_store_path'] = myconfig.data_store_path
        harvestInfo_1['response_url'] = myconfig.response_url
        harvestInfo_1['data_source_id'] = ds_id_1
        harvestInfo_1['harvest_id'] = 8
        harvestInfo_1['batch_number'] = batch_id_1
        harvestInfo_1['advanced_harvest_mode'] = "STANDARD"
        harvestInfo_1['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo_1['mode'] = "TEST"
        harvestInfo_1['requestHandler'] = "grequests"

        batch_id_2 = "JSONLD_T2"
        ds_id_2 = 9
        harvestInfo_2 = {}
        harvestInfo_2['uri'] = 'file:///' + myconfig.abs_path + '/tests/resources/test_source/jsonld/thread_test_sitemap_2.xml'
        harvestInfo_2['provider_type'] = 'JSONLD'
        harvestInfo_2['harvest_method'] = 'JSONLD'
        harvestInfo_2['data_store_path'] = myconfig.data_store_path
        harvestInfo_2['response_url'] = myconfig.response_url
        harvestInfo_2['data_source_id'] = ds_id_2
        harvestInfo_2['harvest_id'] = 9
        harvestInfo_2['batch_number'] = batch_id_2
        harvestInfo_2['advanced_harvest_mode'] = "STANDARD"
        harvestInfo_2['xsl_file'] = myconfig.abs_path + "/tests/resources/xslt/schemadotorg2rif.xsl"
        harvestInfo_2['mode'] = "TEST"
        harvestInfo_2['requestHandler'] = "grequests"
        # basic or asyncio
        harvestReq_1 = JSONLDHarvester(harvestInfo_1)
        t_1 = threading.Thread(name="one", target=harvestReq_1.harvest)
        t_1.start()

        harvestReq_2 = JSONLDHarvester(harvestInfo_2)
        t_2 = threading.Thread(name="two", target=harvestReq_2.harvest)
        t_2.start()
        both_running = True
        while both_running:
            both_running = t_1.isAlive() or t_2.isAlive()
            time.sleep(1)

        resultFile_1 = myconfig.data_store_path + str(ds_id_1) + os.sep + batch_id_1 + os.sep + "combined.tmp"
        resultFile_2 = myconfig.data_store_path + str(ds_id_2) + os.sep + batch_id_2 + os.sep + "combined.tmp"
        self.assertTrue(os.path.exists(resultFile_1))
        self.assertTrue(os.path.exists(resultFile_2))


        content_1 = self.readFile(resultFile_1)
        self.assertIn('<url>http://opencoredata/id/resource/', content_1)
        self.assertNotIn('<id>http://dx.doi.org/10', content_1)
        content_2 = self.readFile(resultFile_2)
        self.assertIn('<id>http://dx.doi.org/10', content_2)
        self.assertNotIn('<url>http://opencoredata/id/resource/', content_2)



    def only_during_development_test_small_text_site_map_balto_php(self):
        batch_id = "JSONLD_4"
        ds_id = 3
        harvestInfo = {}
        #harvestInfo['uri'] = 'http://balto.opendap.org/opendap/site_map.txt'
        #harvestInfo['uri'] = 'https://ssdb.iodp.org/dataset/sitemap.xml'
        #harvestInfo['uri'] = 'http://data.neotomadb.org/sitemap.xml'
        #harvestInfo['uri'] = 'https://earthref.org/MagIC/contributions.sitemap.xml'
        #harvestInfo['uri'] = 'http://get.iedadata.org/doi/xml-sitemap.php'
        #harvestInfo['uri'] = 'http://opencoredata.org/sitemap.xml'
        #harvestInfo['uri'] = 'http://opencoredata.org/sitemapCSDCOData.xml'
        harvestInfo['uri'] = 'http://opentopography.org/sitemap.xml'
        #harvestInfo['uri'] = 'http://wiki.linked.earth/sitemap.xml'
        #harvestInfo['uri'] = 'https://www.bco-dmo.org/sitemap.xml'
        #harvestInfo['uri'] = 'https://www.unavco.org/data/demos/doi/sitemap.xml'
        #harvestInfo['uri'] = 'http://ds.iris.edu/files/sitemap.xml'
        #harvestInfo['uri'] = 'https://portal.edirepository.org/sitemap_index.xml'
        #harvestInfo['uri'] = 'file:///' + myconfig.abs_path + '/tests/resources/test_source/jsonld/bco_sitemap.xml'
        #harvestInfo['uri'] = 'file:///' + myconfig.abs_path + '/tests/resources/test_source/jsonld/thread_test_sitemap_1.xml'
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
        harvestInfo['requestHandler'] = "grequests"
        # basic or asyncio
        #harvestReq = JSONLDHarvester(harvestInfo)
        #t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        #t.start()
        harvester = JSONLDHarvester(harvestInfo)
        harvester.harvest()

    def fun_test_instance_vs_class_variables(self):

        harvestInfo = {}
        harvestInfo['mode'] = "TEST"
        harvestInfo['xsl_file'] = ""
        harvester_1 = JSONLDHarvester(harvestInfo)
        harvester_2 = JSONLDHarvester(harvestInfo)

        #unitialised class primitive variables can be set at instance level
        print(harvester_2.getbatchSize())
        harvester_1.setbatchSize(50)
        print(harvester_2.getbatchSize())
        harvester_2.setbatchSize(20)
        print(harvester_1.getbatchSize())
        print(harvester_2.getbatchSize())

        # unitialised class variables eg list or dict are shared by instances
        # uncomment self.testList = [] in the constructor to see the difference
        harvester_1.addItemtoTestList("one stuff")
        harvester_1.printTestList()

        harvester_2.addItemtoTestList("two stuff")
        harvester_2.printTestList()

        harvester_1.testList.clear()

        harvester_2.addItemtoTestList("two more stuff")
        harvester_1.printTestList()
        harvester_1.addItemtoTestList("one more stuff")
        harvester_1.printTestList()
        harvester_2.addItemtoTestList("two more more stuff")

        harvester_2.printTestList()





if __name__ == '__main__':
    unittest.main()