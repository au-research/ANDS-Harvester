import unittest
import pprint
import myconfig
from harvester_daemon import HarvesterDaemon
import os
import pymysql
import sys

class test_harvester_daemon(unittest.TestCase):

    def test_creation(self):
        daemon = self.helper_get_daemon()
        self.assertIsInstance(daemon, HarvesterDaemon)

    def helper_get_daemon(self):
        daemon = HarvesterDaemon(myconfig.run_dir + '/daemon.pid')
        return daemon

if __name__ == '__main__':
    unittest.main()