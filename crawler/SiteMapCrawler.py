from xml.dom.minidom import getDOMImplementation
from utils.Request import Request
import hashlib
from xml.dom.minidom import parse, parseString
import os, json
from utils.Logger import Logger as MyLogger
from utils.Database import DataBase as MyDataBase
from utils.RedisPoster import RedisPoster
from datetime import datetime


class SiteMapCrawler:
    mLogger = None
    mDataBase = None
    redisPoster = None
    stopped = False
    name = "SiteMapCrawler"
    sitemap_urls = []
    links_to_crawl = []

    def __init__(self, harvestInfo):
        self.redisPoster = RedisPoster()
        self.mLogger = MyLogger()
        self.mDatabase = MyDataBase()
        self.harvestInfo = harvestInfo
        self.sitemap_urls = [harvestInfo.get("uri")]
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
            for url in self.sitemap_urls:
                r = Request(url)
                response = r.getData()
                if response[0] == '<':
                    self.parseXmlSitemap(response)
                else:
                    self.parseTextSitemap(response)

    def parseTextSitemap(self, response):
        for url in str(response).splitlines():
            self.links_to_crawl.append(url)

    def parseXmlSitemap(self, response):
        xml = parseString(response)
        if xml.firstChild.tagName == 'sitemapindex':
            for loc in xml.getElementsByTagName('loc'):
                print(loc.firstChild.data)
                self.parse_sitemap(loc.firstChild.data)
        elif xml.firstChild.tagName == 'urlset':
            for loc in xml.getElementsByTagName('loc'):
                print(loc.firstChild.data)
                self.links_to_crawl.append(loc.firstChild.data)

    def getLinksToCrawl(self):
        return self.links_to_crawl

    def setLinksToCrawl(self, links_to_crawl):
        self.links_to_crawl = links_to_crawl


