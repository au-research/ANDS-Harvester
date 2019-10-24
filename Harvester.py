import os
from xml.dom.minidom import Document
from datetime import datetime, timezone
import time
from utils.RedisPoster import RedisPoster
from utils.Logger import Logger as MyLogger
from utils.Database import DataBase as MyDataBase
from utils.Request import Request
from utils.XSLT2Transformer import XSLT2Transformer
import subprocess
import myconfig
import json, numbers

class Harvester():
    startUpTime = 0
    pageCount = 0
    recordCount = 0
    harvestInfo = None
    data = None
    __xml = None
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
    mode = 'HARVEST'
    completed = False
    storeFileExtension = 'xml'
    resultFileExtension = 'xml'
    redisPoster = False
    combineFiles = False

    def __init__(self, harvestInfo):
        self.__xml = Document()
        self.data = None
        self.startUpTime = int(time.time())
        self.harvestInfo = harvestInfo
        self.mode = harvestInfo['mode']
        self.redisPoster = RedisPoster()
        self.logger = MyLogger()
        self.database = MyDataBase()



    def setupdirs(self):
        number_to_keep = 3
        # set up the data source path
        self.outputDir = self.harvestInfo['data_store_path'] + str(self.harvestInfo['data_source_id'])
        if not os.path.exists(self.outputDir):
            os.makedirs(self.outputDir)
        elif len(os.listdir(self.outputDir)) > number_to_keep:
            the_files = self.listdir_fullpath(self.outputDir)
            the_files.sort(key=os.path.getmtime, reverse=True)
            for i in range(number_to_keep, len(the_files)):
                fileName = the_files[i]
                try:
                    if os.path.isfile(the_files[i]):
                        os.unlink(the_files[i])
                    else:
                        self.emptyDirectory(the_files[i])
                        os.rmdir(the_files[i])
                except PermissionError as e:
                    self.logger.logMessage("Unable to remove %s" % fileName, "ERROR")
        #set up the batch path
        self.outputDir = self.outputDir + os.sep + str(self.harvestInfo['batch_number'])
        if not os.path.exists(self.outputDir):
            os.makedirs(self.outputDir)
        else:
            self.emptyDirectory(self.outputDir)


    def harvest(self):
        self.setupdirs()
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.getHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()

    def crosswalk(self):
        self.setStatus('REGENERATING CONTENT')
        self.setUpCrosswalk()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()


    def listdir_fullpath(self, d):
        return [os.path.join(d, f) for f in os.listdir(d)]

    def setCombineFiles(self, tf):
        self.combineFiles = tf

    def emptyDirectory(self, directory):
        for the_file in os.listdir(directory):
            file_path = os.path.join(directory, the_file)
            try:
                if os.path.isfile(file_path):
                    os.unlink(file_path)
                else:
                    self.emptyDirectory(file_path)
                    os.rmdir(file_path)
            except PermissionError as e:
                self.logger.logMessage("Unable to emptyDirectory %s" % file_path, "ERROR")

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
        #clean up previous crosswalk and import content
           self.outputDir = self.harvestInfo['data_store_path'] + str(self.harvestInfo['data_source_id'])
           self.outputDir = self.outputDir + os.sep + str(self.harvestInfo['batch_number'])
           for file in os.listdir(self.outputDir):
               if file.endswith(self.resultFileExtension) or \
                       file.endswith(self.resultFileExtension + ".validated") or\
                       file.endswith(self.resultFileExtension + ".processed"):
                   try:
                       if os.path.isfile(self.outputDir + os.sep + file):
                           os.unlink(self.outputDir + os.sep + file)
                       else:
                           self.emptyDirectory(self.outputDir + os.sep + file)
                           os.rmdir(self.outputDir + os.sep + file)
                   except PermissionError as e:
                       self.logger.logMessage("Unable to remove %s" % (self.outputDir + os.sep + file), "ERROR")



    def runCrossWalk(self):
        if self.stopped or self.harvestInfo['xsl_file'] is None or self.harvestInfo['xsl_file'] == '':
            return
        transformCount = 0
        for file in os.listdir(self.outputDir):
            if file.endswith(self.storeFileExtension):
                transformCount += 1
        for file in os.listdir(self.outputDir):
            if file.endswith(self.storeFileExtension):
                self.logger.logMessage("runCrossWalk %s" %file)
                outFile = self.outputDir + os.sep + file.replace(self.storeFileExtension, self.resultFileExtension)
                inFile = self.outputDir + os.sep + file
                try:
                    self.setStatus('RUNNING %s CROSSWALK ' %str(transformCount), "Generating %s:" % outFile)
                    transformerConfig = {'xsl': self.harvestInfo['xsl_file'], 'outFile': outFile, 'inFile': inFile}
                    tr = XSLT2Transformer(transformerConfig)
                    tr.transform()
                    os.chmod(outFile, 0o775)
                except subprocess.CalledProcessError as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s " %(e.output.decode()), "ERROR")
                    msg = "'ERROR WHILE RUNNING CROSSWALK %s '" %(e.output.decode())
                    self.handleExceptions(msg, transformCount == 1)
                except Exception as e:
                    self.logger.logMessage("ERROR WHILE RUNNING CROSSWALK %s" %(e), "ERROR")
                    self.handleExceptions(e, transformCount == 1)


    def postHarvestData(self):
        if self.stopped or self.mode == 'TEST':
            return
        self.setStatus('HARVESTING' , "batch number completed:"+ self.harvestInfo['batch_number'])
        postRequest = Request(self.harvestInfo['response_url'] + "?ds_id=" + str(self.harvestInfo['data_source_id'])
                              + "&batch_id=" + self.harvestInfo['batch_number'] + "&status=" + self.__status)
        self.data = postRequest.postCompleted()
        del postRequest

    def postHarvestError(self):
        if self.stopped or self.mode == 'TEST':
            return
        self.setStatus(self.__status, "batch number " + self.harvestInfo['batch_number'] + " completed witherror:" + str.strip(self.errorLog))
        postRequest = Request(self.harvestInfo['response_url'] + "?ds_id=" + str(self.harvestInfo['data_source_id'])
                              + "&batch_id=" + self.harvestInfo['batch_number'] + "&status=" + self.__status)
        self.logger.logMessage("ERROR URL:" + postRequest.getURL(), "INFO")
        self.data = postRequest.postCompleted()
        del postRequest

    def postHarvestNoRecords(self):
        if self.stopped or self.mode == 'TEST':
            return
        self.setStatus(self.__status, "batch number " + self.harvestInfo['batch_number'] + " completed witherror:" + str.strip(self.errorLog))
        postRequest = Request(self.harvestInfo['response_url'] + "?ds_id=" + str(self.harvestInfo['data_source_id'])
                              + "&batch_id=" + self.harvestInfo['batch_number'] + "&status=" + self.__status)
        self.logger.logMessage("NO RECORDS RETURNED URL:" + postRequest.getURL(), "INFO")
        self.data = postRequest.postCompleted()
        del postRequest


    def updateHarvestRequest(self):
        self.checkHarvestStatus()
        self.write_summary()
        if self.stopped or self.mode == 'TEST':
            return
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
        attempts = 0
        while attempts < 3:
            try:
                conn = self.database.getConnection()
                cur = conn.cursor()
                cur.execute("UPDATE %s SET `status` ='%s', `message` ='%s' where `harvest_id` = %s"
                            % (myconfig.harvest_table,
                               self.__status,
                               json.dumps(statusDict).replace("'", "\\\'"),
                               str(self.harvestInfo['harvest_id'])))
                conn.commit()
                message = json.dumps(statusDict).replace("'", "\\\'")
                self.redisPoster.postMesage('datasource.' + str(self.harvestInfo['data_source_id']) + '.harvest',
                                            message)
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.logger.logMessage(
                    '(updateHarvestRequest) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")


    def checkHarvestStatus(self):
        if self.stopped or self.mode == 'TEST':
            return
        attempts = 0
        while attempts < 3:
            try:
                conn = self.database.getConnection()
                cur = conn.cursor()
                cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                            %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "STOPPED%"))
                if(cur.rowcount > 0):
                    self.__status = cur.fetchone()[0]
                    self.stopped = True
                    self.logger.logMessage("HARVEST STOPPED WHILE RUNNING", "DEBUG")
                if self.completed:
                    cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                                %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "SCHEDULED%"))
                    if(cur.rowcount > 0):
                        self.__status = cur.fetchone()[0]
                        self.stopped = True
                        self.logger.logMessage("HARVEST COMPLETED / RE-SCHEDULED", "DEBUG")
                    cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                                %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "IMPORTING%"))
                    if(cur.rowcount > 0):
                        self.__status = cur.fetchone()[0]
                        self.stopped = True
                        self.logger.logMessage("REGISTRY IS IMPORTING", "DEBUG")
                cur.execute("SELECT status FROM %s where `harvest_id` =%s and `status` like '%s';"
                            %(myconfig.harvest_table, str(self.harvestInfo['harvest_id']), "COMPLETED%"))
                if(cur.rowcount > 0):
                    self.__status = cur.fetchone()[0]
                    self.stopped = True
                    self.logger.logMessage("HARVEST COMPLETED", "DEBUG")
                cur.close()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.logger.logMessage(
                    '(checkHarvestStatus) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")

    def storeHarvestData(self):
        if self.stopped or not(self.data):
            return
        try:
            #if data is JSON then save the json as well as a XML serialised copy
            if self.is_json(self.data):
                jsonObj = json.loads(self.data, strict=False)
                self.storeJsonData(jsonObj, str(self.pageCount))
                self.storeDataAsXML(jsonObj, str(self.pageCount))
            else:
                self.outputFilePath = self.outputDir + os.sep + str(self.pageCount) + "." + self.storeFileExtension
                self.logger.logMessage("Harvester (storeHarvestData) %s " % (self.outputFilePath), "DEBUG")
                dataFile = open(self.outputFilePath, 'w')
                self.setStatus("HARVESTING", self.outputFilePath)
                dataFile.write(self.data)
                dataFile.close()
                os.chmod(self.outputFilePath, 0o775)
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("Harvester (storeHarvestData) %s " % (str(repr(e))), "ERROR")


    def storeJsonData(self, data, fileName):
        if self.stopped:
           return
        try:
            outputFilePath = self.outputDir + os.sep + fileName + ".json"
            self.logger.logMessage("Harvester (storeJsonData) %s " % (outputFilePath), "DEBUG")
            dataFile = open(outputFilePath, 'w')
            json.dump(data, dataFile)
            dataFile.close()
            os.chmod(outputFilePath, 0o775)
        except Exception as e:
            self.handleExceptions(e)
            self.logger.logMessage("Harvester (storeJsonData) %s " % (str(repr(e))), "ERROR")


    def storeDataAsXML(self, data, fileName):
        if self.stopped:
           return
        try:
            self.__xml = Document()
            root = self.__xml.createElement('datasets')
            self.__xml.appendChild(root)
            self.outputFilePath = self.outputDir + os.sep + fileName + "." + self.storeFileExtension
            dataFile = open(self.outputFilePath, 'w')
            if isinstance(data, list):
                for j in data:
                    ds = self.__xml.createElement('dataset')
                    self.parse_element(ds, j)
                    root.appendChild(ds)
                self.__xml.writexml(dataFile)
                dataFile.close()
            else:
                self.parse_element(root, data)
                self.__xml.writexml(dataFile)
                dataFile.close()
            os.chmod(self.outputFilePath, 0o775)
            self.logger.logMessage("Harvester (storeDataAsXML) %s " % (self.outputFilePath), "DEBUG")
        except Exception as e:
            self.logger.logMessage("Harvester (storeDataAsXML) %s " % (str(repr(e))), "ERROR")

    # https://stackoverflow.com/questions/11294535/verify-if-a-string-is-json-in-python

    def is_json(self, myjson):
        try:
            json_object = json.loads(myjson)
        except ValueError as e:
            return False
        return True

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
                                   %(str(self.harvestInfo['harvest_id']),self.errorLog), "ERROR")
        self.updateHarvestRequest()
        self.write_summary()
        self.stopped = True

    def write_summary(self):
        """ Generates and writes the harvest summary into the `summary` db field.
        All sizes are in MB
        All durations are in seconds
        """
        start = datetime.fromtimestamp(self.startUpTime)
        end = datetime.now()
        dtformat = '%Y-%m-%d %H:%M:%S'
        utcformat = '%Y-%m-%dT%H:%M:%SZ'
        output_count = 0
        output_size = 0

        if self.outputFilePath is not None:
            output_count = 1
            output_size = self.get_size(self.outputFilePath)
        elif self.outputDir is not None:
            output_count = len(self.get_files(self.outputDir, 'xml'))
            output_size = self.get_size(self.outputDir)

        harvest_frequency = 'once'
        if 'harvest_frequency' in self.harvestInfo and self.harvestInfo['harvest_frequency'] != '':
            harvest_frequency = self.harvestInfo['harvest_frequency']

        summary = {
            'id': self.harvestInfo['harvest_id'],
            'batch': self.harvestInfo['batch_number'],
            # 'mode': self.harvestInfo['mode'],
            'method': self.harvestInfo['harvest_method'],
            'advanced_harvest_mode': self.harvestInfo['advanced_harvest_mode'],
            'crosswalk': 'xsl_file' in self.harvestInfo and self.harvestInfo['xsl_file'] != "",
            'frequency': harvest_frequency,
            'url': self.harvestInfo['uri'],
            'error': {
                'log': str.strip(self.errorLog),
                'errored': self.errored
            },
            'completed': self.completed,
            'start_utc': datetime.fromtimestamp(self.startUpTime, timezone.utc).strftime(utcformat),
            'end_utc': datetime.now(timezone.utc).strftime(utcformat),
            'start': start.strftime(dtformat),
            'end': end.strftime(dtformat),
            'duration': (end - start).seconds,
            'output': {
                'file': self.outputFilePath,
                'dir': self.outputDir,
                'count': output_count,
                'size': output_size
            }
        }
        self.write_to_field(summary, 'summary')

    @staticmethod
    def get_files(target, extension="*"):
        """
        Return a list of files from a directory
        To use:
            get_files('/var/harvested_contents/22/', 'xml')
            get_files('/usr/lib')

        :param target:
        :param extension: (optional)
        :return:
        """
        path, dirs, files = next(os.walk(target))
        result = []

        if extension is "*":
            return files

        for file in files:
            if file.endswith(extension):
                result.append(file)
        return result

    @staticmethod
    def get_size(target):
        """
        get size of the target in MB

        :param target:
        :return: integer
        """
        if os.path.isfile(target):
            return os.path.getsize(target) / (1024*1024.0)
        elif os.path.isdir(target):
            folder_size = 0
            for (path, dirs, files) in os.walk(target):
                for file in files:
                    filename = os.path.join(path, file)
                    folder_size += os.path.getsize(filename)
            return folder_size / (1024*1024.0)
        else:
            return 0

    def write_to_field(self, summary, field):

        """
        Writes into the harvests table
        Retries 3 times

        To use:
            self.write_to_field(summary, field)

        :param summary: the content that will be json.dumps
        :param field: the field where it will be written to
        """
        if self.stopped or self.mode == 'TEST':
            return
        attempts = 0
        while attempts < 3:
            try:
                conn = self.database.getConnection()
                cur = conn.cursor()
                cur.execute("UPDATE %s SET `%s` ='%s' where `harvest_id` = %s"
                            % (
                                myconfig.harvest_table,
                                field,
                                json.dumps(summary),
                                str(self.harvestInfo['harvest_id']))
                            )
                conn.commit()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.logger.logMessage('(write_to_field) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")

    def isCompleted(self):
        return self.completed

    def isStopped(self):
        return self.stopped

    def stop(self):
        if self.stopped:
            return
        self.logger.logMessage("STOPPING harvestID: %s WITH STATUS: %s"
                               %(str(self.harvestInfo['harvest_id']), self.__status), "INFO")
        self.updateHarvestRequest()
        self.stopped = True

    def rescheduleHarvest(self):
        self.__status= 'SCHEDULED'
        self.message = "harvester shut down"
        self.logger.logMessage("harvest_id: %s status: %s"
                               %(str(self.harvestInfo['harvest_id']) ,self.__status), "INFO")
        try:
            self.updateHarvestRequest()
            self.stopped = True
        except Exception as e:
            self.logger.logMessage("CAN NOT RESCHEDULE harvestid: %s ERROR: %s"
                                   %(str(self.harvestInfo['harvest_id']), str(repr(e))), "ERROR")


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

    def handleNoRecordsMatch(self, errorCode):
        self.__status = 'NORECORDS'
        self.errorLog = self.errorLog + errorCode + ", "
        self.updateHarvestRequest()
        self.postHarvestNoRecords()
        self.stopped = True

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

    # the simplest json to XML parser
    def parse_element(self, root, j):
        if j is None:
            return
        if isinstance(j, dict):
            for key in j.keys():
                value = j[key]
                if isinstance(value, list):
                    for e in value:
                        elem = self.getElement(key)
                        self.parse_element(elem, e)
                        root.appendChild(elem)
                else:
                    if key.isdigit():
                        elem = self.__xml.createElement('item')
                        elem.setAttribute('value', key)
                    else:
                        elem = self.getElement(key)
                    self.parse_element(elem, value)
                    root.appendChild(elem)
        elif isinstance(j, str):
            text = self.__xml.createTextNode(j.encode('ascii', 'xmlcharrefreplace').decode('utf-8').encode('unicode-escape').decode('utf-8'))
            root.appendChild(text)
        elif isinstance(j, numbers.Number):
            text = self.__xml.createTextNode(str(j))
            root.appendChild(text)
        else:
            raise Exception("bad type %s for %s" % (type(j), j,))


    def getElement(self, jsonld_key):
        qName = jsonld_key.replace(' ', '')
        qName = qName.replace('@', '')
        # some ckan harvest during tests produced {"": "true"} fields
        if qName == '':
            qName = 'unknown'
        ns = qName.split("#", 2)
        if len(ns) == 2:
            elem = self.__xml.createElement(ns[1])
        else:
            elem = self.__xml.createElement(qName)
        return elem
