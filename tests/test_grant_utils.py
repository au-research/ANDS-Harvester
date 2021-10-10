import time
import unittest
from utils.GrantUtils import TroveClient
from utils.GrantUtils import SolrClient
import myconfig

class test_grant_utils(unittest.TestCase):

    def not_a_test_test_client(self):
        tc = TroveClient(myconfig.trove_api2_url, myconfig.trove_api_key, "/tmp/arc_grantpubs.xml")
        tc.harvest()


    def not_a_test_solr_client(self):
        sc = SolrClient(myconfig.solr_url)
        sc.get_trove_groups("/tmp/arc_admin_institutions.xml")
