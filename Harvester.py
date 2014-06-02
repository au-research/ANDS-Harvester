try:
    import urllib.request as urllib2
except:
    import urllib2
import os
import json
from xml.dom.minidom import parseString
from datetime import datetime
from dateutil import parser
from xml.dom.minidom import Document
import numbers
from subprocess import call
import myconfig

class Request:
    data = False
    url = False

    def __init__(self, url):
        self.url = url

    def getData(self):
        try:
            req = urllib2.Request(self.url)
            f = urllib2.urlopen(req,timeout=30)
            self.data = f.read()
            return self.data
        except Exception as e:
            raise RuntimeError("getData %s Exception %r " %(self.url, e))


    def postData(self, data):
        try:
            req = urllib2.Request(self.url)
            f = urllib2.urlopen(req, data, timeout=30)
            self.data = f.read()
            return self.data
        except Exception as e:
            raise RuntimeError("postData %s Exception %r " %(self.url, e))

class XSLT2Transformer:

    #XSLT 2.0 transformer run in java

    __xsl = "data.gov.au_json_to_rif-cs.xsl"

    def __init__(self, transformerConfig):
        self.__xsl = transformerConfig['xsl']
        self.__outfile = transformerConfig['outFile']
        self.__inputFile = transformerConfig['inFile']

    def transform(self):
        shellCommand = myconfig.java_home + " "
        shellCommand = shellCommand + " -cp " + myconfig.saxon_jar + " net.sf.saxon.Transform"
        shellCommand = shellCommand + " -o " + self.__outfile
        shellCommand = shellCommand + " " + self.__inputFile
        shellCommand = shellCommand + " " + self.__xsl
        call(shellCommand, shell=True)


class Harvester:
    harvestInfo = False
    data = False
    logger = False
    __status = 'WAITING'
    database = False
    errored = False
    stopped = False
    outputFilePath = False
    outputDir = False

    def __init__(self, harvestInfo, logger, database):
        self.harvestInfo = harvestInfo
        self.logger = logger
        self.database = database

    def harvest(self):
        self.getHarvestData()
        self.postHarvestData()
        self.finishHarvest()

    def getHarvestData(self):
        if self.stopped:
            return
        try:
            self.setStatus('GETTING-DATA')
            getRequest = Request(self.harvestInfo['uri'])
            self.data = getRequest.getData()
            del getRequest
        except Exception as e:
            self.handleExceptions(e)

    def postHarvestData(self):
        if self.stopped:
            return
        self.setStatus('POST-DATA')
        postRequest = Request(self.harvestInfo['response_url'])
        #TODO: add required params to data
        postRequest.postData(self.data)
        del postRequest
        self.finishHarvest()

    def updateHarvestRequest(self):
        self.checkHarvestStatus()
        if self.stopped:
            return
        self.logger.logMessage("harvest_id: %s status: %s" %(str(self.harvestInfo['harvest_id']) ,self.__status))
        conn = self.database.getConnection()
        cur = conn.cursor()
        #status = conn.escape_string(self.__status)
        cur.execute("UPDATE python_harvest_requests SET `status` ='%s' where `harvest_id` = %s" %(self.__status, str(self.harvestInfo['harvest_id'])))
        conn.commit()
        del cur
        conn.close()

    def checkHarvestStatus(self):
        conn = self.database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT status FROM python_harvest_requests where `harvest_id` =%s and `status` like '%s';" %(str(self.harvestInfo['harvest_id']), "STOPPED%"))
        if(cur.rowcount > 0):
            self.__status = cur.fetchone()[0]
            self.stopped = True
            self.logger.logMessage("HARVEST STOPPED WHILE RUNNING")
        cur.close()
        del cur
        conn.close()


    def storeHarvestData(self, fileExt='xml'):
        if self.errored or self.stopped:
            return
        directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id']) + os.sep + str(self.harvestInfo['harvest_id']) + os.sep
        if not os.path.exists(directory):
            os.makedirs(directory)
        self.outputDir = directory
        self.outputFilePath = directory + str(self.harvestInfo['batch_number']) + "." + fileExt
        dataFile = open(self.outputFilePath, 'wb')
        self.setStatus("SAVING DATA: %s" %self.outputFilePath)
        dataFile.write(self.data)
        os.chmod(self.outputFilePath, 777)
        dataFile.close()

    def getStatus(self):
        return self.__status

    def getInfo(self):
        return "STATUS: %s, METHOD: %s, HARVEST ID: %s, DATA_SOURCE_TITLE %s SCHEDULED %s" %(self.__status, self.harvestInfo['harvest_method'], str(self.harvestInfo['harvest_id']),self.harvestInfo['title'],self.harvestInfo['until_date'])

    def finishHarvest(self):
        if self.errored:
            return
        self.__status= 'COMPLETED'
        self.updateHarvestRequest()

    def stop(self):
        self.stopped = True
        print("STOPPING harvestID: %s WITH STATUS: %s" %(str(self.harvestInfo['harvest_id']), self.__status))

    def rescheduleHarvest(self):
        self.stopped = True
        self.__status= 'RE-SCHEDULED: %s' %datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.logger.logMessage("harvest_id: %s status: %s" %(str(self.harvestInfo['harvest_id']) ,self.__status))
        try:
            conn = self.database.getConnection()
            cur = conn.cursor()
            cur.execute("UPDATE python_harvest_requests SET `status` ='%s' , `next_run` = date('%s') where `harvest_id` = %s" %(self.__status, str(datetime.now()), str(self.harvestInfo['harvest_id'])))
            conn.commit()
            del cur
            conn.close()
        except Exception as e:
            print("CAN NOT RESCHEDULE harvestid: %s" %str(self.harvestInfo['harvest_id']))


    def setStatus(self, status):
        self.__status = status
        self.updateHarvestRequest()

    def handleExceptions(self, exception):
        self.__status= 'STOPPED BY EXCEPTION: %s' %(repr(exception).replace("'", "").replace('"', ""))
        self.updateHarvestRequest()
        self.errored = True
        self.stopped = True







