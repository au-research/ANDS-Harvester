import unittest
import pprint
import myconfig
from Harvester import *
from harvester_daemon import HarvesterDaemon
import os
import pymysql
import sys

'''
This test class require the harvester_daemon to be fully unit tested first
'''
class test_harvester(unittest.TestCase):

    def test_creation(self):
        harvester = self.helper_get_harvester()
        #self.assertIsInstance(harvester, Harvester)

    def helper_get_harvester(self):
        harvester = None
        #harvester = Harvester(harvestInfo = {}, logger = None, database = None)
        return harvester

if __name__ == '__main__':
    unittest.main()