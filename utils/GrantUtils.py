import os
import urllib
import urllib
import urllib.parse as urlparse
from utils.Request import Request
from lxml import etree
import myconfig

class TroveClient:
    trove_url = None
    trove_api_key = None
    result_file_path = None

    def __init__(self, url, key, file_path):
        self.trove_url = url
        self.trove_api_key = key
        self.result_file_path = file_path

    def harvest(self):

        file = open(self.result_file_path, "w")
        file.write("<?xml version='1.0' encoding='UTF-8'?>\n<troveGrants>\n")
        file.close()
        #print(os.path.getsize(self.result_file_path))
        url = self.trove_url + "/result"
        params = {}
        params["key"] = self.trove_api_key
        params["n"] = "100"
        params["zone"] = "article"
        params["include"] = "workversions"
        params["q"] = "purl.org/au-research/grants/arc"
        params["s"] = "*"
        query = urllib.parse.urlencode(params)
        data = self.getArcGrantsPublication(url + "?" + query)
        #print(data)
        next = self.processData(data)
        while next is not None:
            #print(next)
            data = self.getArcGrantsPublication(self.trove_url + next + "&key=" + self.trove_api_key)
            next = self.processData(data)
            #print(os.path.getsize(self.result_file_path))
        file = open(self.result_file_path, "a")
        file.write("\n</troveGrants>")
        file.close()

    def getArcGrantsPublication(self, url):
        request = Request(url)
        result = request.getData()
        return result

    def processData(self, data):
        file = open(self.result_file_path, "ab")
        try:
            styledoc = etree.parse(myconfig.abs_path + "/resources/trove_result_to_publications.xsl")
            transform = etree.XSLT(styledoc)
            doc = etree.XML(data.encode())
            result = transform(doc)
            #print(result)
            result.write_output(file)
            file.write(os.linesep.encode("utf-8"))
            file.close()
            records = doc.find(".//records[1]")
            next = records.attrib["next"]
            return next
        except Exception as e:
            file.close()
            #print(e)
            return None


class SolrClient:
    solr_url = None
    def __init__(self, url):
        self.solr_url = url

    def get_trove_groups(self, file_path):
        url = self.solr_url + "/portal/select"
        file = open(file_path, "wb")
        params = {}
        params["fl"] = "title,key,group,identifier_value"
        params["fq"] = "group:*Organisations || group:*Institutions"
        params["q"] = "type:group"
        # Order by group descending so "Trove - People and Organisations" will bubble up
        # and "Australian Research Institutions" will show up last
        params["sort"] = "group desc"
        params["rows"] = "1000"
        params["wt"] = "xml"
        query = urllib.parse.urlencode(params)
        request = Request(url + "?" + query)
        result = request.getData()
        styledoc = etree.parse(myconfig.abs_path + "/resources/solr_admin_institutions.xsl")
        transform = etree.XSLT(styledoc)
        doc = etree.XML(result.encode())
        result = transform(doc)
        #print(result)
        result.write_output(file)
        file.close()
        # "http://130.56.62.162:8983/solr/portal/select
        # ?fl=title%2Ckey%2Cgroup%2Cidentifier_value
        # &fq=group%3A*Organisations%20%7C%7C%20group%3A*Institutions
        # &q=type%3Agroup
        # &rows=1000
        # &sort=group%20desc
        # &wt=xml"
