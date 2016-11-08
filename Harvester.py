try:
    import urllib.request as urllib2
except:
    import urllib2
import redis
import os
import json
from xml.dom.minidom import parseString
from datetime import datetime, timezone
import time
from xml.dom.minidom import Document
import numbers
import subprocess
import myconfig

class Request:
    data = None
    url = None

    def __init__(self, url):
        self.url = url

    def getData(self):
        self.data = None
        try:
            req = urllib2.Request(self.url)
            fs = urllib2.urlopen(req, timeout=60)
            self.data = fs.read()
            return self.data
        except Exception as e:
            raise RuntimeError(str(e) + " Error while trying to connect to: " + self.url)

    def getURL(self):
        return self.url

    def postData(self, data):
        try:
            req = urllib2.Request(self.url)
            f = urllib2.urlopen(req, data, timeout=30)
            self.data = f.read()
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


class RedisPoster:

    poster = False

    def __init__(self):
        self.poster = redis.StrictRedis(host='localhost', port=6379, db=0)

    def postMesage(self, chanel, message):
        self.poster.publish(chanel, message)


class XSLT2Transformer:

    #XSLT 2.0 transformer run in java

    def __init__(self, transformerConfig):
        self.__xsl = transformerConfig['xsl']
        self.__outfile = transformerConfig['outFile']
        self.__inputFile = transformerConfig['inFile']

    def transform(self):
        shellCommand = myconfig.java_home + " "
        shellCommand += " -cp " + myconfig.saxon_jar + " net.sf.saxon.Transform"
        shellCommand += " -o " + self.__outfile
        shellCommand += " " + self.__inputFile
        shellCommand += " " + self.__xsl
        subprocess.check_output(shellCommand, stderr=subprocess.STDOUT, shell=True)
        subprocess.call(shellCommand, shell=True)


class Harvester():
    startUpTime = 0
    pageCount = 0
    recordCount = 0
    harvestInfo = None
    data = None
    logger = None
    database = None
    outputFilePath = None
    outputDir = None
    __status = 'WAITING'
    listSize = 'unknown'
    message = ''
    errorLog = ""
    errored = False
    stopped = False
    completed = False
    storeFileExtension = 'xml'
    resultFileExtension = 'xml'
    redisPoster = False

    def __init__(self, harvestInfo, logger, database):
        self.startUpTime = int(time.time())
        self.harvestInfo = harvestInfo
        self.redisPoster = RedisPoster()
        self.logger = logger
        self.database = database
        self.cleanPreviousHarvestRecords()
        self.updateHarvestRequest()
        self.setUpCrosswalk()

    def harvest(self):
        self.getHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def cleanPreviousHarvestRecords(self):
        directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id'])
        number_to_keep = 3
        if not os.path.exists(directory):
            os.makedirs(directory)
        elif len(os.listdir(directory)) > number_to_keep:
            the_files = self.listdir_fullpath(directory)
            the_files.sort(key=os.path.getmtime, reverse=True)
            for i in range(number_to_keep, len(the_files)):
                try:
                    if os.path.isfile(the_files[i]):
                        os.unlink(the_files[i])
                    else:
                        self.deleteDirectory(the_files[i])
                        os.rmdir(the_files[i])
                except Exception as e:
                    self.logger.logMessage(e)

    def listdir_fullpath(self, d):
        return [os.path.join(d, f) for f in os.listdir(d)]

    def deleteDirectory(self, directory):
        for the_file in os.listdir(directory):
            file_path = os.path.join(directory, the_file)
            try:
                if os.path.isfile(file_path):
                    os.unlink(file_path)
                else:
                    self.deleteDirectory(file_path)
                    os.rmdir(file_path)
            except Exception as e:
                self.logger.logMessage(e)

    def getHarvestData(self):
        if self.stopped:
            return
        try:
            self.setStatus('HARVESTING')
            getRequest = Request(self.harvestInfo['uri'])
            self.data = getRequest.getData()
            del getRequest
        except Exception as e:
            self.handleExceptions(e)

    def setUpCrosswalk(self):
        if self.harvestInfo['xsl_file'] is not None and self.harvestInfo['xsl_file'] != '':
           self.storeFileExtension = 'tmp'


    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        outFile = self.outputDir  + os.sep + str(self.harvestInfo['batch_number']) + "." + self.resultFileExtension
        self.setStatus("HARVESTING", "RUNNING CROSSWALK")
        try:
            transformerConfig = {'xsl': self.harvestInfo['xsl_file'],
                                 'outFile' : outFile, 'inFile' : self.outputFilePath}
            tr = XSLT2Transformer(transformerConfig)
            tr.transform()
        except subprocess.CalledProcessError as e:
            self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()))
            self.handleExceptions("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()))
        except Exception as e:
            self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s" %(e))
            self.handleExceptions(e)

    def postHarvestData(self):
        if self.stopped:
            return
        self.setStatus('HARVESTING' , "batch number completed:"+ self.harvestInfo['batch_number'])
        postRequest = Request(self.harvestInfo['response_url'] + str(self.harvestInfo['data_source_id'])
                              + "/?batch=" + self.harvestInfo['batch_number'] + "&status=" + self.__status)
        self.data = postRequest.postCompleted()
        del postRequest

    def postHarvestError(self):
        if self.stopped:
            return
        self.setStatus(self.__status, "batch number " + self.harvestInfo['batch_number'] + " completed witherror:" + str.strip(self.errorLog))
        postRequest = Request(self.harvestInfo['response_url'] + str(self.harvestInfo['data_source_id'])
                              + "/?batch=" + self.harvestInfo['batch_number'] + "&status=" + self.__status)
        self.logger.logMessage("ERROR URL:" + postRequest.getURL())
        self.data = postRequest.postCompleted()
        del postRequest


    def updateHarvestRequest(self):
        self.checkHarvestStatus()
        if self.stopped:
            return
        try:
            conn = self.database.getConnection()
        except Exception as e:
            self.logger.logMessage("Database Connection Error: %s" %(str(repr(e))))
            return
        cur = conn.cursor()
        upTime = int(time.time()) - self.startUpTime
        statusDict = {'status':self.__status,
                      'batch_number':self.harvestInfo['batch_number'],
                      'mode' : self.harvestInfo['mode'],
                      'message': self.message,
                      'importer_message': self.message,
                      'error':{'log':str.strip(self.errorLog), 'errored': self.errored},
                      'completed':str(self.completed),
                      'start_utc' : str(datetime.fromtimestamp(self.startUpTime,
                                                               timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')),
                      'output':{'file': self.outputFilePath, 'dir': self.outputDir},
                      'progress':{'current':self.recordCount, 'total':self.listSize,
                                  'time':str(upTime),'start':str(self.startUpTime), 'end':''}
                    }
        try:
            cur.execute("UPDATE %s SET `status` ='%s', `message` ='%s' where `harvest_id` = %s"
                        %(myconfig.harvest_table,
                          self.__status,
                          json.dumps(statusDict).replace("'", "\\\'"),
                          str(self.harvestInfo['harvest_id'])))
            conn.commit()
            message = json.dumps(statusDict).replace("'", "\\\'")
            self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest', message)

            del cur
            conn.close()
        except Exception as e:
            self.logger.logMessage("Database Error: (updateHarvestRequest) %s" %(str(repr(e))))

    def checkHarvestStatus(self):
        if self.stopped:
            return
        try:
            conn = self.database.getConnection()
        except Exception as e:
            return
        try:
            cur = conn.cursor()
            cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                        %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "STOPPED%"))
            if(cur.rowcount > 0):
                self.__status = cur.fetchone()[0]
                self.stopped = True
                self.logger.logMessage("HARVEST STOPPED WHILE RUNNING")
            if self.completed:
                cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                            %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "SCHEDULED%"))
                if(cur.rowcount > 0):
                    self.__status = cur.fetchone()[0]
                    self.stopped = True
                    self.logger.logMessage("HARVEST COMPLETED / RE-SCHEDULED")
                cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                            %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "IMPORTING%"))
                if(cur.rowcount > 0):
                    self.__status = cur.fetchone()[0]
                    self.stopped = True
                    self.logger.logMessage("REGISTRY IS IMPORTING")
            cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                        %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "COMPLETED%"))
            if(cur.rowcount > 0):
                self.__status = cur.fetchone()[0]
                self.stopped = True
                self.logger.logMessage("HARVEST COMPLETED")
            cur.close()
            del cur
            conn.close()
        except Exception as e:
            self.logger.logMessage("Database Error: (checkHarvestStatus) %s" %(str(repr(e))))

    def storeHarvestData(self):
        if self.stopped:
            return
        directory = self.harvestInfo['data_store_path'] + os.sep + str(self.harvestInfo['data_source_id']) + os.sep
        if not os.path.exists(directory):
            os.makedirs(directory)
            os.chmod(directory, 0o777)
        self.outputDir = directory
        self.outputFilePath = directory + str(self.harvestInfo['batch_number']) + "." + self.storeFileExtension
        dataFile = open(self.outputFilePath, 'wb', 0o777)
        self.setStatus("HARVESTING", self.outputFilePath)
        dataFile.write(self.data)
        dataFile.close()

    def getStatus(self):
        self.checkHarvestStatus()
        return self.__status

    def getInfo(self):
        self.checkHarvestStatus()
        self.checkRunTime()
        upTime = int(time.time()) - self.startUpTime
        return "STATUS: %s, UP TIME: %s, METHOD: %s, HARVEST ID: %s, DATA_SOURCE_TITLE %s SCHEDULED %s" \
               %(self.__status, str(upTime), self.harvestInfo['harvest_method'],
                 str(self.harvestInfo['harvest_id']),self.harvestInfo['title'],
                 self.harvestInfo['until_date'])

    def finishHarvest(self):
        self.completed = True
        self.__status= 'HARVEST COMPLETED'
        if(self.errorLog != ''):
            self.logger.logMessage("HARVEST ID:%s COMPLETED WITH SOME ERRORS:%s"
                                   %(str(self.harvestInfo['harvest_id']),self.errorLog))
        self.updateHarvestRequest()
        self.stopped = True

    def isCompleted(self):
        return self.completed

    def isStopped(self):
        return self.stopped

    def stop(self):
        if self.stopped:
            return
        self.logger.logMessage("STOPPING harvestID: %s WITH STATUS: %s"
                               %(str(self.harvestInfo['harvest_id']), self.__status))
        self.updateHarvestRequest()
        self.stopped = True

    def rescheduleHarvest(self):
        self.__status= 'SCHEDULED'
        self.message = "harvester shut down"
        self.logger.logMessage("harvest_id: %s status: %s"
                               %(str(self.harvestInfo['harvest_id']) ,self.__status))
        try:
            self.updateHarvestRequest()
            self.stopped = True
        except Exception as e:
            self.logger.logMessage("CAN NOT RESCHEDULE harvestid: %s ERROR: %s"
                                   %(str(self.harvestInfo['harvest_id']), str(repr(e))))


    def setStatus(self, status, message="no message"):
        self.__status = status
        self.message = message
        self.updateHarvestRequest()

    def checkRunTime(self):
        if self.stopped:
            return
        upTime = int(time.time()) - self.startUpTime
        if upTime > myconfig.max_up_seconds_per_harvest:
            self.errorLog = 'HARVEST TOOK LONGER THAN %s minutes' \
                            %(str(myconfig.max_up_seconds_per_harvest/60)) + self.errorLog
            self.handleExceptions(exception={'message':'HARVEST TOOK LONGER THAN %s minutes'
                                                       %(str(myconfig.max_up_seconds_per_harvest/60))})


    def handleExceptions(self, exception, terminate=True):
        self.errored = True
        if terminate:
            self.__status= 'ERROR'
            self.errorLog = self.errorLog  + str(exception).replace('\n',',').replace("'", "").replace('"', "") + ", "
            self.updateHarvestRequest()
            self.postHarvestError()
            self.stopped = True
        else:
            self.errorLog = self.errorLog + str(exception).replace('\n',',').replace("'", "").replace('"', "") + ", "
