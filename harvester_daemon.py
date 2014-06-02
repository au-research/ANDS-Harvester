# harvester daemon script in python
# for ANDS registry
# Author: u4187959
# created 12/05/2014
#

from datetime import datetime
import os
import sys
import pymysql
import myconfig
import asyncio
import Harvester
from harvest_handlers import *
from apscheduler.schedulers.asyncio import AsyncIOScheduler


class HarvesterDaemon:
    __scheduler = False
    __logger = False
    __database = False
    __harvestRequests = {}
    __runningHarvests = {}
    __maxSimHarvestRun = 3
    __lastLogCounter = 999
    __harvesterDefinitionFile = False
    def __init__(self):
        self.__lastLogCount = 99
        self.__database = self.__DataBase()
        self.__logger = self.__Logger()
        self.__harvesterDefinitionFile = myconfig.run_dir + "harvester_definition.json"
        self.setupEnv()
        self.describeModules()

    class __Logger:
        __fileName = False
        __file = False
        __current_log_time = False
        def __init__(self):
            self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
            if not os.path.exists(myconfig.log_dir):
                os.makedirs(myconfig.log_dir)
            self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"

        def logMessage(self, message):
            self.rotateLogFile()
            self.__file = open(self.__fileName, "a")
            self.__file.write(message + " %s"  % datetime.now() + "\n")
            self.__file.close()

        def rotateLogFile(self):
            if(self.__current_log_time != datetime.now().strftime("%Y-%m-%d")):
                self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
                self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"

    class __DataBase:
        __connection = False
        __db_host = ''
        __unix_socket = '/tmp/mysql.sock'
        __db_user = ''
        __db_passwd = ''
        __db = ''
        def __init__(self):
            self.__host = myconfig.db_host
            self.__user = myconfig.db_user
            self.__passwd = myconfig.db_passwd
            self.__db = myconfig.db


        def getConnection(self):
            #if not(self.__connection):
            try:
                self.__connection = pymysql.connect(host=self.__host, unix_socket='/tmp/mysql.sock', user=self.__user, passwd = self.__passwd, db = self.__db)
            except:
                e = sys.exc_info()[1]
                print("Database Exception %s" %(e))
            return self.__connection

    def handleException(self, harvestId, exception):
        harvesterStatus = 'STOPPED BY EXCEPTION: %s' %(repr(exception).replace("'", "").replace('"', ""))
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("UPDATE python_harvest_requests SET `status` ='%s' where `harvest_id` = %s" %(harvesterStatus, str(harvestId)))
        conn.commit()
        cur.close()
        del cur
        conn.close()

    def addHarvestRequest(self, harvestID, dataSourceId, nextRun, previousRun, mode, batchNumber):
        self.__logger.logMessage("DataSource ID: %s, harvest_id: %s " %(str(dataSourceId),str(harvestID)))
        harvestInfo = {}
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("select `attribute`, `value` FROM dbs_registry.data_source_attributes where `attribute` in('title','harvest_method','uri','provider_type','advanced_harvest_mode','oai_set', 'advanced_harvest_mode') and `data_source_id` =%s;" %str(dataSourceId))
        for r in cur:
            harvestInfo[r[0]] = r[1]
        harvestInfo['mode'] = mode
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['data_source_id'] = dataSourceId
        harvestInfo['harvest_id'] = harvestID
        harvestInfo['batch_number'] = batchNumber
        harvestInfo['from_date'] = previousRun
        harvestInfo['until_date'] = nextRun
        try:
            harvester_module = __import__(harvestInfo['harvest_method'], globals={}, locals={}, fromlist=[], level=0)
            class_ = getattr(harvester_module, harvestInfo['harvest_method'])
            myHarvester = class_(harvestInfo, self.__logger, self.__database)
            self.__harvestRequests[harvestID] = myHarvester
        except ImportError as e:
            self.handleException(harvestID, e)
        cur.close()

    def manageHarvests(self):
        self.checkForHarvestRequests()
        self.printLogs(int(len(self.__runningHarvests)) + int(len(self.__harvestRequests)))
        #clean up completed harvests
        if len(self.__runningHarvests) > 0:
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                if harvestReq.getStatus() == "COMPLETED" or harvestReq.getStatus().startswith("STOPPED"):
                    del harvestReq
                    del self.__runningHarvests[harvestID]
        #if max hasn't reached add more harvests are WAITING
        if len(self.__harvestRequests) > 0 and len(self.__runningHarvests) < self.__maxSimHarvestRun:
            for harvestID in list(self.__harvestRequests):
                try:
                    harvestReq = self.__harvestRequests[harvestID]
                    if harvestReq.getStatus() == "WAITING":
                        self.__runningHarvests[harvestID] = harvestReq
                        del self.__harvestRequests[harvestID]
                        harvestReq = self.__runningHarvests[harvestID]
                        harvestReq.harvest()
                    if len(self.__runningHarvests) >= self.__maxSimHarvestRun:
                        break
                except KeyError as e:
                    print("harvestID %s already scheduled" %str(harvestID))




    def checkForHarvestRequests(self):
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM python_harvest_requests where `status` like '%SCHEDULED%' and ('next_run' is null or `next_run` <=timestamp('" + str(datetime.now()) + "'));")
        if(cur.rowcount > 0):
            self.__logger.logMessage("Scheduling Harvest Count:%s" %str(cur.rowcount))
            for r in cur:
                self.addHarvestRequest(r[0],r[1],r[3],r[4],r[5],r[6])
        cur.close()
        del cur
        conn.close()

    def describeModules(self):
        self.__harvesterDefinitionFile
        harvesterDifinitions = "{'harvester_methods':\n\t"
        notFirst = False
        for files in os.listdir(myconfig.run_dir + '/harvest_handlers'):
            if files.endswith(".py"):
                modulename = os.path.splitext(files)[0]
                harvester_module = __import__(modulename, globals={}, locals={}, fromlist=[], level=0)
                class_ = getattr(harvester_module, modulename)
                if notFirst:
                    harvesterDifinitions = harvesterDifinitions + ","
                notFirst = True
                harvesterDifinitions = harvesterDifinitions + class_.__doc__.strip()
        harvesterDifinitions = harvesterDifinitions + "}"
        self.saveHarvestDefinition(harvesterDifinitions)


    def saveHarvestDefinition(self, harvesterDifinitions):
        #save definition to file
        file = open(self.__harvesterDefinitionFile, "w+")
        file.write(harvesterDifinitions)
        file.close()
        #and to the database
        conn = self.__database.getConnection()
        cur = conn.cursor()
        #cur.execute
        cur.execute("UPDATE configs set `value`='%s' where `key`='harvester_methods';" %(harvesterDifinitions.replace("'", "\\\'")))
        conn.commit()
        cur.close()
        del cur
        conn.close()


    def setupEnv(self):
        if not os.path.exists(myconfig.data_store_path):
            os.makedirs(myconfig.data_store_path)
            os.chmod(myconfig.data_store_path, 777)


    def run(self):
        print("STARTING...")
        print(datetime.now().strftime("%Y-%m-%d-%H:%M"))
        self.__scheduler = AsyncIOScheduler()
        self.__scheduler.add_job(self.manageHarvests, 'interval', seconds=30, max_instances=5)
        self.__scheduler.start()
        print('Press Ctrl+C to exit')
        try:
            asyncio.get_event_loop().run_forever()
        except (KeyboardInterrupt, SystemExit):
            self.shutDown()
        except Exception as e:
            print("error %r" %(e))
            pass

        #self.__scheduler = Scheduler(daemon=True)
        #atexit.register(lambda: self.__scheduler.shutdown(wait=False))
        #self.__scheduler.add_job(self.manageHarvests, 'interval', seconds=10)
        #self.__scheduler.start()

    def printLogs(self, hCounter):
        if(self.__lastLogCounter > 0 or hCounter > 0):
            self.__lastLogCounter = hCounter
            print('RUNNING: %s PENDING: %s' %(str(len(self.__runningHarvests)), str(len(self.__harvestRequests))))
            print('###################################################')
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                print(harvestReq.getInfo())
            print('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
            for harvestID in list(self.__harvestRequests):
                harvestReq = self.__harvestRequests[harvestID]
                print(harvestReq.getInfo())
            print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')



    def shutDown(self):
        print("SHUTTING DOWN...")
        self.__scheduler.shutdown()
        print(self.__runningHarvests)
        if len(self.__runningHarvests) > 0:
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                if harvestReq.getStatus() != "COMPLETED" and not(harvestReq.getStatus().startswith("STOPPED")):
                    harvestReq.stop()
                    harvestReq.rescheduleHarvest()
                    del harvestReq
                    del self.__runningHarvests[harvestID]
        sys.exit()




if __name__ == '__main__':
    sys.path.append(myconfig.run_dir + '/harvest_handlers')
    hd = HarvesterDaemon()
    hd.run()



