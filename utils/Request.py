import requests
import ssl
import os
from requests.adapters import HTTPAdapter
from requests.exceptions import ConnectionError

class Request:
    """
    urllib based class that used to retries or send data to and from any webresource
    """
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
        """
        retieves the response data as text from the given url
        :return:
        :rtype:
        """
        retryCount = 3
        httpAdapter = HTTPAdapter(max_retries=retryCount)
        session = requests.Session()
        session.mount(self.url, httpAdapter)
        data = ''
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.get(self.url, headers=header)
            response.raise_for_status()
            data = response.text
            session.close()
        except Exception as e:
            raise RuntimeError("Error while trying (%s) times to connect to url:%s " %(str(retryCount), self.url))
        else:
            return data

    def getURL(self):
        return self.url

    def setURL(self, url):
        self.url = url

    def postCompleted(self):
        """
        actually this method just send a GET request
        this is the "agreed" communication between the harvester and the registry
        :return:
        :rtype:
        """
        retryCount = 3
        httpAdapter = HTTPAdapter(max_retries=retryCount)
        session = requests.Session()
        session.mount(self.url, httpAdapter)
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.get(self.url, headers=header)
            response.raise_for_status()
            data = response.text
            session.close()
        except Exception as e:
            pass