import json
import unittest
import responses

import requests
import io, myconfig
from utils.Request import Request


class test_request(unittest.TestCase):

    def readTestfile(self, path):
        f = io.open(myconfig.abs_path + '/tests/resources/test_source/get/' + path, mode="r")
        data = f.read()
        f.close()
        return data

    def test_get_webpage(self):
        r = Request('http://google.com')
        data = r.getData()
        self.assertIn("<!doctype html>", data)

    @responses.activate
    def test_charset_utf_8_responses(self):
        def request_callback(request):
            data = self.readTestfile('encoding_test.xml')
            request_url = request.url
            resp_body = data
            return 200, {}, resp_body

        responses.add_callback(
            responses.GET, 'http://not_sure_what',
            callback=request_callback,
            content_type='text/xml; charset=utf-8',
        )
        response = requests.get('http://not_sure_what')
        self.assertIn("ISO-8859-1", response.apparent_encoding)
        self.assertIn("utf-8", response.encoding)
        self.assertIn("Colombelli-Négrel", response.text)

    @responses.activate
    def test_no_charset_responses(self):
        def request_callback(request):
            data = self.readTestfile('encoding_test.xml')
            request_url = request.url
            resp_body = data
            return 200, {}, resp_body

        responses.add_callback(
            responses.GET, 'http://not_sure_what',
            callback=request_callback,
            content_type='text/xml',
        )
        response = requests.get('http://not_sure_what')
        self.assertIn("ISO-8859-1", response.apparent_encoding)
        contentType = response.headers.__getitem__('Content-Type').split(';')
        self.assertIn("ISO-8859-1", response.apparent_encoding)
        self.assertIn("ISO-8859-1", response.encoding)
        if len(contentType) < 2:
            data = response.content.decode('utf-8')
        self.assertIn("Colombelli-Négrel", data)
        self.assertIn("Colombelli-NÃ©grel", response.text)


if __name__ == '__main__':
    unittest.main()