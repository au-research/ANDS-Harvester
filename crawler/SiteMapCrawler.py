from xml.dom.minidom import getDOMImplementation
from utils.Request import Request
import hashlib
from xml.dom.minidom import parse, parseString
import os, json
from utils.Logger import Logger as MyLogger
from utils.Database import DataBase as MyDataBase
from utils.RedisPoster import RedisPoster
import myconfig


class SiteMapCrawler:
    mLogger = None
    mDataBase = None
    redisPoster = None
    stopped = False
    name = "SiteMapCrawler"
    sitemap_urls = ""
    links_to_crawl = []

    def __init__(self, harvestInfo):
        self.redisPoster = RedisPoster()
        self.mLogger = MyLogger()
        self.mDatabase = MyDataBase()
        self.harvestInfo = harvestInfo
        self.sitemap_url = harvestInfo.get("uri")
        self.links_to_crawl = []
        self.name = harvestInfo.get('data_source_slug')
        self.storeFileExtension = "tmp"
        directory = self.harvestInfo['data_store_path'] + str(self.harvestInfo['data_source_id']) + os.sep + str(
            self.harvestInfo['batch_number'])
        if not os.path.exists(directory):
            os.makedirs(directory)
            os.chmod(directory, 0o777)
        self.outputDir = directory

    def parse_sitemap(self, url=None):
        if url is not None:
            r = Request(url)
            response = r.getData()
            if response[0] == '<':
                self.parseXmlSitemap(response)
            else:
                self.parseTextSitemap(response)
        else:
            r = Request(self.sitemap_url)
            response = r.getData()
            if response[0] == '<':
                self.parseXmlSitemap(response)
            else:
                self.parseTextSitemap(response)

    def parseTextSitemap(self, response):
        for url in str(response).splitlines():
            if len(self.links_to_crawl) >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                continue

            self.links_to_crawl.append(url)

    def parseXmlSitemap(self, response):
        xml = parseString(response)
        smi = xml.getElementsByTagName('sitemapindex')
        urlset = xml.getElementsByTagName('urlset')
        if len(smi) > 0:
            for loc in xml.getElementsByTagName('loc'):
                if len(self.links_to_crawl) >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                    continue
                self.parse_sitemap(loc.firstChild.data)
        elif len(urlset) > 0:
            for loc in xml.getElementsByTagName('loc'):
                if len(self.links_to_crawl) >= myconfig.test_limit and self.harvestInfo['mode'] == 'TEST':
                    continue
                self.links_to_crawl.append(loc.firstChild.data)

    def getLinksToCrawl(self):
        return self.links_to_crawl

    def setLinksToCrawl(self, links_to_crawl):
        self.links_to_crawl = links_to_crawl


