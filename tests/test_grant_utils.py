import time
import unittest
from utils.GrantUtils import TroveClient
from utils.GrantUtils import SolrClient


class test_grant_utils(unittest.TestCase):

    def not_a_test_test_client(self):
        tc = TroveClient("http://api.trove.nla.gov.au/v2","kv813g2u51fg804u", "/tmp/arc_grantpubs.xml")
        tc.harvest()


    def not_a_test_solr_client(self):
        sc = SolrClient("http://130.56.62.162:8983/solr")
        sc.get_trove_groups("/tmp/arc_admin_institutions.xml")
