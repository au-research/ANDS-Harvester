import requests
from requests.adapters import HTTPAdapter
import urllib3


class Request:
    """
    urllib based class that used to retries or send data to and from any webresource
    """
    data = None
    url = None
    logger = None
    # how many retries before throwing an Error
    retryCount = 1
    def __init__(self, url):
        self.retryCount = 3
        urllib3.disable_warnings()
        self.url = url

    def getData(self):
        """
        retieves the response data as text from the given url
        :return:
        :rtype:
        """
        httpAdapter = HTTPAdapter(max_retries=self.retryCount)
        session = requests.Session()
        session.mount(self.url, httpAdapter)
        data = ''
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.get(self.url, headers=header, verify=False)
            response.raise_for_status()
            data = response.text
            #print("getData %s" % str(data))
            session.close()
        except Exception as e:
            raise RuntimeError("Error while trying (%s) times to connect to url:%s " %(str(self.retryCount), self.url))
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
        httpAdapter = HTTPAdapter(max_retries=self.retryCount)
        session = requests.Session()
        session.mount(self.url, httpAdapter)
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.get(self.url, headers=header, verify=False)
            response.raise_for_status()
            data = response.text
            #print("postCompleted %s" %str(data))
            session.close()
        except Exception as e:
            pass