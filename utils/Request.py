import urllib.request
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
        retryCount = 0
        while retryCount < 5:
            try:
                req = urllib.request.Request(self.url)
                req.add_header('User-Agent', 'ARDC Harvester')
                fs = urllib.request.urlopen(req, timeout=60)
                if fs.headers.get_content_charset() is not None:
                    self.data = fs.read().decode(fs.headers.get_content_charset())
                else:
                    self.data = fs.read().decode('utf-8')
                del req, fs
                return self.data
            except Exception as e:
                print("ERROR %s : E: %s" %(self.url, str(e)))
                retryCount += 1
                if retryCount > 4:
                    raise RuntimeError("Error while trying (%s) times to connect to url:%s " %(str(retryCount), self.url))

    def getURL(self):
        return self.url

    def setURL(self, url):
        self.url = url

    def postData(self, data):
        try:
            req = urllib.request.Request(self.url)
            req.add_header('User-Agent', 'ARDC Harvester')
            fs = urllib.request.urlopen(req, data, timeout=30)
            if fs.headers.get_content_charset() is not None:
                self.data = fs.read().decode(fs.headers.get_content_charset())
            else:
                self.data = fs.read().decode('utf-8')
            del req, fs
            return self.data
        except Exception as e:
            raise RuntimeError(str(e) + " Error while trying to connect to: " + self.url)

    def postCompleted(self):
        try:
            req = urllib.request.Request(self.url)
            fs = urllib.request.urlopen(req, timeout=30)
            self.data = f.read()
            del req, fs
            return self.data
        except Exception as e:
            pass