import unittest
import myconfig
from utils.Request import Request


class test_request(unittest.TestCase):


    def test_get_local_file(self):
        r = Request('file:///' + myconfig.run_dir + 'tests/resources/test_source/get/get_json.json')
        data = r.getData()
        print(data)
        self.assertIn("success", data)

    def test_get_webpage(self):
        r = Request('https://www.google.com/')
        data = r.getData()
        print(data)
        self.assertIn("<!doctype html>", data)

if __name__ == '__main__':
    unittest.main()