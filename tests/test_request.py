import unittest
from utils.Request import Request


class test_request(unittest.TestCase):


     def test_get_webpage(self):
        r = Request('https://www.google.com/')
        data = r.getData()
        self.assertIn("<!doctype html>", data)

if __name__ == '__main__':
    unittest.main()