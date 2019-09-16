import unittest
import pprint
import myconfig
import os
import pymysql
import sys

class test_config(unittest.TestCase):

    def test_creation(self):
        self.assertIsInstance(myconfig.run_dir, str)
        self.assertIsInstance(myconfig.response_url, str)
        self.assertIsInstance(myconfig.data_store_path, str)
        self.assertIsInstance(myconfig.log_dir, str)
        self.assertIsInstance(myconfig.java_home, str)
        self.assertIsInstance(myconfig.saxon_jar, str)
        self.assertIsInstance(myconfig.db_host, str)
        self.assertIsInstance(myconfig.db_user, str)
        self.assertIsInstance(myconfig.db_passwd, str)
        self.assertIsInstance(myconfig.db, str)
        self.assertIsInstance(myconfig.harvest_table, str)
        self.assertIsInstance(myconfig.tcp_connection_limit, int)


    def test_database_connection(self):
        self.assertTrue(self.helper_is_connected(myconfig.harvest_table))

    def helper_is_connected(self, table):
        try:
            db = pymysql.connect(
                host = myconfig.db_host,
                user = myconfig.db_user,
                passwd = myconfig.db_passwd,
                db = myconfig.db)
            cursor = db.cursor()
            cursor.execute("SELECT VERSION()")
            results = cursor.fetchone()
            if results:
                return True
            else:
                return False
        except :
            e = sys.exc_info()[1]
            raise RuntimeError("Database Exception %s" %(e))
        return False

if __name__ == '__main__':
    unittest.main()