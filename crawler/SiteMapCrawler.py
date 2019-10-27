from utils.Request import Request
from xml.dom.minidom import parseString
import myconfig

# a very simple sitemap crawler
# able to parse xml (sitemapindex or urlset) and plain text sitemap files
# will recursively fetch all urls
# getLinksToCrawl will return the set of urls it has discovered

class SiteMapCrawler:

    mode = "TEST"
    links_to_crawl = []

    #@params  mode (TEST or (not test) eg HARVEST)

    def __init__(self, mode="HARVEST"):
        self.mode = mode
        self.links_to_crawl = []

    # the main method to start discovering urls listed in the sitemap_url
    def parse_sitemap(self, sitemap_url=None):
        try:
            if sitemap_url is not None:
                r = Request(sitemap_url)
                response = r.getData()
                # the fastest way to test if the response is XML
                if response[0] == '<':
                    self.parseXmlSitemap(response)
                else:
                    self.parseTextSitemap(response)
        except Exception as e:
            raise Exception(e)

    # text sitemap is simple just a list of urls
    # one url per line
    def parseTextSitemap(self, response):
        for url in str(response).splitlines():
            if len(self.links_to_crawl) >= myconfig.test_limit and self.mode == 'TEST':
                continue

            self.links_to_crawl.append(url)
    # xml sitemap can be sitemapindex that will point to more sitemaps <loc>
    # or urlset that will contain urls <loc> element
    def parseXmlSitemap(self, response):
        xml = parseString(response)
        smi = xml.getElementsByTagName('sitemapindex')
        urlset = xml.getElementsByTagName('urlset')
        if len(smi) > 0:
            for loc in xml.getElementsByTagName('loc'):
                if len(self.links_to_crawl) >= myconfig.test_limit and self.mode == 'TEST':
                    continue
                #call parse sitemap but this time with a url param
                self.parse_sitemap(loc.firstChild.data)
        elif len(urlset) > 0:
            for loc in xml.getElementsByTagName('loc'):
                if len(self.links_to_crawl) >= myconfig.test_limit and self.mode == 'TEST':
                    continue
                self.links_to_crawl.append(loc.firstChild.data)

    # getLinksToCrawl will return the set of urls it has discovered
    def getLinksToCrawl(self):
        return self.links_to_crawl



