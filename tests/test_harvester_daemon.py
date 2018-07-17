from __future__ import absolute_import

import unittest
import myconfig
import os
import pymysql
import sys
from harvester_daemon import HarvesterDaemon
from harvester_daemon import Logger

class test_harvester_daemon(unittest.TestCase):

    def test_creation(self):
        daemon = self.helper_get_daemon()
        self.assertIsInstance(daemon, HarvesterDaemon)

    def test_log_writable(self):
        daemon = self.helper_get_daemon()
        daemon.setupEnv()
        self.assertTrue(os.path.isdir(myconfig.log_dir))
        self.assertTrue(os.access(myconfig.log_dir, os.W_OK))

    def test_logger_creation(self):
        logger = Logger()
        self.assertIsInstance(logger, Logger)

    def helper_get_daemon(self):
        daemon = HarvesterDaemon(myconfig.run_dir + '/daemon.pid')
        return daemon

if __name__ == '__main__':
    unittest.main()