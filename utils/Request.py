try:
    import urllib.request as urllib2
except:
    import urllib2
import urllib.parse as urlparse
import ssl
import os
#from utils.Logger import Logger as MyLogger

class Request:
    data = None
    url = None
    logger = None
    def __init__(self, url):
        if (not os.environ.get('PYTHONHTTPSVERIFY', '') and
                getattr(ssl, '_create_unverified_context', None)):
            ssl._create_default_https_context = ssl._create_unverified_context
        self.url = url
        #self.logger = MyLogger()

    def getData(self):
        self.data = None
        retryCount = 0
        while retryCount < 5:
            try:
                req = urllib2.Request(self.url)
                req.add_header('User-Agent', 'ARDC Harvester')
                fs = urllib2.urlopen(req, timeout=60)
                if fs.headers.get_content_charset() is not None:
                    self.data = fs.read().decode(fs.headers.get_content_charset())
                else:
                    self.data = fs.read().decode('utf-8')
                return self.data
            except Exception as e:
                retryCount += 1
                if retryCount > 4:
                    raise RuntimeError(str(e) + " Error while trying (%s) times to connect to url:%s " %(str(retryCount), self.url))

    def getDatabyQuery(self, params):
        try:
            query = urlparse.urlencode(params)
            req = urllib2.Request(self.url + "?" + query)
            req.add_header('User-Agent', 'ARDC Harvester')
            fs = urllib2.urlopen(req, timeout=30)
            if fs.headers.get_content_charset() is not None:
                self.data = fs.read().decode(fs.headers.get_content_charset())
            else:
                self.data = fs.read().decode('utf-8')
            return self.data
        except Exception as e:
            raise RuntimeError(str(e) + " Error while trying to connect to: " + self.url)


    def getURL(self):
        return self.url

    def postData(self, data):
        try:
            req = urllib2.Request(self.url)
            req.add_header('User-Agent', 'ARDC Harvester')
            fs = urllib2.urlopen(req, data, timeout=30)
            if fs.headers.get_content_charset() is not None:
                self.data = fs.read().decode(fs.headers.get_content_charset())
            else:
                self.data = fs.read().decode('utf-8')
            return self.data
        except Exception as e:
            raise RuntimeError(str(e) + " Error while trying to connect to: " + self.url)

    def postCompleted(self):
        try:
            req = urllib2.Request(self.url)
            f = urllib2.urlopen(req, timeout=30)
            self.data = f.read()
            return self.data
        except Exception as e:
            pass