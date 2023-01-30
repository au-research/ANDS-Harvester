import unittest
import myconfig
import os, io
from harvest_handlers.DataCiteQueryHarvester import DataCiteQueryHarvester
from utils.Request import Request


class test_datacite_query_harvester(unittest.TestCase):

    def readFile(self, path):
        f = io.open(path, mode="r")
        data = f.read()
        f.close()
        return data


    def only_when_developing_test_datacite_query_harvester(self):
        batch_id = "DATACITE_HARVEST"
        ds_id = 14
        harvestInfo = {}
        harvestInfo['uri'] = 'https://api.test.datacite.org/dois/?query=relatedIdentifiers.relatedIdentifier:*anzctr*+descriptions.description:*HESANDA*'
        harvestInfo['provider_type'] = 'DataCiteQuery'
        harvestInfo['harvest_method'] = 'DataCiteQuery'
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_source_id'] = ds_id
        harvestInfo['harvest_id'] = '11'
        harvestInfo['batch_number'] = batch_id
        harvestInfo['advanced_harvest_mode'] = "STANDARD"
        harvestInfo['xsl_file'] = "resources/xslt/HeSANDA/HeSANDA_Datacite_To_Rifcs.xsl"
        harvestInfo['mode'] = "TEST"
        # harvestReq = JSONLDHarvester.JSONLDHarvester(harvestInfo)
        # t = threading.Thread(name='JSONLD', target=harvestReq.harvest)
        # t.start()
        harvester = DataCiteQueryHarvester(harvestInfo)
        harvester.harvest()
        tempFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "10.80298_test_doi_63489fc003dc5.tmp"
        resultFile = myconfig.data_store_path + str(ds_id) + os.sep + batch_id + os.sep + "10.80298_test_doi_63489fc003dc5.xml"
        self.assertTrue(os.path.exists(tempFile))
        self.assertTrue(os.path.exists(resultFile))
        content = self.readFile(resultFile)
        self.assertIn('collection type="health.dataset"', content)
        content = self.readFile(tempFile)
        self.assertIn('<identifier identifierType="DOI">10.80298/TEST_DOI_63489FC003DC5</identifier>', content)


if __name__ == '__main__':
    unittest.main()