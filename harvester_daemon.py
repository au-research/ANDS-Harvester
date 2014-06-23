# harvester daemon script in python
# for ANDS registry
# Author: u4187959
# created 12/05/2014
#

from datetime import datetime
import sys, os, time, atexit
from signal import SIGTERM
import pymysql
import myconfig
import time
import Harvester
import string
import json
import threading
from harvest_handlers import *


class Logger:
    __fileName = False
    __file = False
    __current_log_time = False
    def __init__(self):
        self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
        self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"

    def logMessage(self, message):
        self.rotateLogFile()
        self.__file = open(self.__fileName, "a", 0o777)
        self.__file.write(message + " %s"  % datetime.now() + "\n")
        self.__file.close()

    def rotateLogFile(self):
        if(self.__current_log_time != datetime.now().strftime("%Y-%m-%d")):
            self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
            self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"

class Daemon(object):
    """
    Subclass Daemon class and override the run() method.
    """
    def __init__(self, pidfile, stdin='/dev/null', stdout='/dev/null', stderr='/dev/null'):
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.pidfile = pidfile
        self.__logger = Logger()

    def daemonize(self):
        """
        Deamonize, do double-fork magic.
        """
        try:
            pid = os.fork()
            if pid > 0:
                # Exit first parent.
                sys.exit(0)
        except OSError as e:
            message = "Fork #1 failed: {}\n".format(e)
            sys.stderr.write(message)
            sys.exit(1)

        # Decouple from parent environment.
        os.chdir("/")
        os.setsid()
        os.umask(0)

        # Do second fork.
        try:
            pid = os.fork()
            if pid > 0:
                # Exit from second parent.
                sys.exit(0)
        except OSError as e:
            message = "Fork #2 failed: {}\n".format(e)
            sys.stderr.write(message)
            sys.exit(1)

        self.__logger.logMessage('deamon going to background, PID: {}'.format(os.getpid()))

        # Redirect standard file descriptors.
        sys.stdout.flush()
        sys.stderr.flush()
        si = open(self.stdin, 'r')
        so = open(self.stdout, 'a+')
        se = open(self.stderr, 'a+')
        os.dup2(si.fileno(), sys.stdin.fileno())
        os.dup2(so.fileno(), sys.stdout.fileno())
        os.dup2(se.fileno(), sys.stderr.fileno())

        # Write pidfile.
        pid = str(os.getpid())
        open(self.pidfile,'w+').write("{}\n".format(pid))

        # Register a function to clean up.


    def delpid(self):
        self.__logger.logMessage("\n\nDELETING PID FILE...")
        os.remove(self.pidfile)

    def start(self):
        """
        Start daemon.
        """
        # Check pidfile to see if the daemon already runs.
        try:
            pf = open(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            pid = None

        if pid:
            message = "Pidfile {} already exist. Daemon already running?\n".format(self.pidfile)
            message += "If you're sure that the harvester is not running delete the pid file and try again!\n"
            sys.stderr.write(message)
            sys.exit(1)

        # Start daemon.
        self.__logger.logMessage("\n\nSTARTING HARVESTER_DAEMON...")
        self.daemonize()
        try:
            self.run()
        except (KeyboardInterrupt, SystemExit):
            self.__logger.logMessage("\n\nSTOPPING...")
            self.shutDown()


    def status(self):
        """
        Get status of daemon.
        """
        try:
            pf = open(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            message = "There is no PID file. is the harvester running?\n"
            sys.stderr.write(message)
            sys.exit(1)

        try:
            procfile = open("/proc/{}/status".format(pid), 'r')
            procfile.close()
            message = "The Harvester is running with the PID {}\n".format(pid)
            sys.stdout.write(message)
        except IOError:
            message = "There is not a process with the PID {}\n".format(self.pidfile)
            sys.stdout.write(message)

    def stop(self):
        """
        Stop the daemon.
        """
        # Get the pid from pidfile.
        self.__logger.logMessage("\n\nSTOPPING HARVESTER_DAEMON...")
        try:
            pf = open(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError as e:
            message = str(e) + "\nHarvester Daemon is not running?\n"
            sys.stderr.write(message)
            sys.exit(1)

        # Try killing daemon process.
        try:
            os.kill(pid, SIGTERM)
            self.__logger.logMessage("\n\nKILLING %s..." %str(pid))
            time.sleep(1)
        except OSError as e:
            print(str(e))
            sys.exit(1)

        try:
            if os.path.exists(self.pidfile):
                self.__logger.logMessage("\n\nDELETING PIDFILE %s..." %self.pidfile)
                os.remove(self.pidfile)
        except IOError as e:
            message = str(e) + "\nCan not remove pid file {}".format(self.pidfile)
            sys.stderr.write(message)
            sys.exit(1)

    def restart(self):
        """
        Restart daemon.
        """
        self.stop()
        time.sleep(1)
        self.start()

    def run(self):

        """You should override this method when you subclass Daemon.

        It will be called after the process has been daemonized by
        start() or restart()."""


class HarvesterDaemon(Daemon):
    __scheduler = False
    __logger = False
    __database = False
    __harvestRequests = {}
    __runningHarvests = {}
    __running_threads = {}
    __maxSimHarvestRun = 3
    __lastLogCounter = 999
    __harvesterDefinitionFile = False
    __startUpTime = None
    __harvestStarted = 0
    __harvestCompleted = 0
    __harvestErrored = 0
    __harvestStopped = 0

    class __Logger:
        __fileName = False
        __file = False
        __current_log_time = False
        def __init__(self):
            self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
            self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"

        def logMessage(self, message):
            self.rotateLogFile()
            self.__file = open(self.__fileName, "a", 0o777)
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
        harvesterStatus = 'STOPPED'
        self.__harvestErrored += 1
        eMessage = repr(exception).replace("'", "").replace('"', "")
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("UPDATE %s SET `status` ='%s', `message` = '%s' where `harvest_id` = %s" %(myconfig.harvest_table, harvesterStatus, eMessage, str(harvestId)))
        conn.commit()
        cur.close()
        del cur
        conn.close()

    def addHarvestRequest(self, harvestID, dataSourceId, nextRun, lastRun, mode, batchNumber):
        self.__logger.logMessage("DataSource ID: %s, harvest_id: %s " %(str(dataSourceId),str(harvestID)))
        harvestInfo = {}
        conn = self.__database.getConnection()
        cur = conn.cursor()
        harvestInfo['crosswalk'] = None
        harvestInfo['xsl_file'] = None
        cur.execute("SELECT * FROM data_sources where `data_source_id` =%s;" %(str(dataSourceId)))
        for r in cur:
            harvestInfo['data_source_id'] = r[0]
            harvestInfo['data_source_slug'] = r[1]
            harvestInfo['data_source_slug'] = r[2]
            harvestInfo['title'] = r[3]
        cur.execute("SELECT `attribute`, `value` FROM data_source_attributes where `attribute` in(%s) and `data_source_id` =%s;" %(myconfig.harvester_specific_datasource_attributes, str(dataSourceId)))
        for r in cur:
            harvestInfo[r[0]] = r[1]
        harvestInfo['mode'] = mode
        harvestInfo['response_url'] = myconfig.response_url
        harvestInfo['data_store_path'] = myconfig.data_store_path
        harvestInfo['harvest_id'] = harvestID
        harvestInfo['batch_number'] = batchNumber
        harvestInfo['from_date'] = lastRun
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
        self.reportToRegistry()
        self.printLogs(int(len(self.__runningHarvests)) + int(len(self.__harvestRequests)))
        #clean up completed harvests
        if len(self.__runningHarvests) > 0:
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                if harvestReq.isCompleted() or harvestReq.getStatus() == "SCHEDULED" or harvestReq.getStatus() == "COMPLETED":
                    self.__harvestCompleted = self.__harvestCompleted + 1
                    del harvestReq
                    if self.__running_threads[harvestID].isAlive() == True:
                        del self.__running_threads[harvestID]
                    del self.__runningHarvests[harvestID]
                elif harvestReq.isStopped() or harvestReq.getStatus() == "STOPPED":
                    self.__harvestStopped = self.__harvestStopped + 1
                    del harvestReq
                    if self.__running_threads[harvestID].isAlive() == True:
                        del self.__running_threads[harvestID]
                    del self.__runningHarvests[harvestID]
        #if max hasn't reached add more harvests that are WAITING
        if len(self.__harvestRequests) > 0 and len(self.__runningHarvests) < self.__maxSimHarvestRun:
            for harvestID in list(self.__harvestRequests):
                try:
                    harvestReq = self.__harvestRequests[harvestID]
                    if harvestReq.getStatus() == "WAITING":
                        self.__runningHarvests[harvestID] = harvestReq
                        del self.__harvestRequests[harvestID]
                        harvestReq = self.__runningHarvests[harvestID]
                        t = threading.Thread(target=harvestReq.harvest)
                        self.__running_threads[harvestID] = t
                        t.start()
                        self.__harvestStarted = self.__harvestStarted + 1
                    if len(self.__runningHarvests) >= self.__maxSimHarvestRun:
                        break
                except KeyError as e:
                    self.__logger.logMessage("harvestID %s already scheduled" %str(harvestID))


    def checkForHarvestRequests(self):
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM "+ myconfig.harvest_table +" where `status` like 'SCHEDULED%' and ('next_run' is null or `next_run` <=timestamp('" + str(datetime.now()) + "'));" )
        if(cur.rowcount > 0):
            self.__logger.logMessage("Scheduling Harvest Count:%s" %str(cur.rowcount))
            for r in cur:
                self.addHarvestRequest(r[0],r[1],r[4],r[5],r[6],r[7])
        cur.close()
        del cur
        conn.close()

    def fixBrokenHarvestRequests(self):
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT count(*) FROM "+ myconfig.harvest_table +" WHERE `status`='HARVESTING' or `status`='WAITING'")
        try:
            result = cur.fetchone()
            if result[0] > 0:
                self.__logger.logMessage("\nFOUND %s BROKEN HARVESTS\nRESCHEDULING...\n" %(str(result[0])))
        except Exception as e:
            pass
        cur.execute("UPDATE "+ myconfig.harvest_table +" SET `status`='SCHEDULED' where `status`='HARVESTING' or `status`='WAITING'")
        conn.commit()
        cur.close()
        del cur
        conn.close()

    def describeModules(self):
        self.__logger.logMessage("\nDESCRIBING HARVESTER MODULES:\n")
        harvesterDefinitions = '{"harvester_config":{"harvester_methods":['
        notFirst = False
        for files in os.listdir(myconfig.run_dir + '/harvest_handlers'):
            if files.endswith(".py"):
                modulename = os.path.splitext(files)[0]
                harvester_module = __import__(modulename, globals={}, locals={}, fromlist=[], level=0)
                class_ = getattr(harvester_module, modulename)
                if notFirst:
                    harvesterDefinitions += ","
                notFirst = True
                harvesterDefinitions += class_.__doc__.strip()
        harvesterDefinitions +=  "]}"
        harvesterDefinitions += self.describeCrossWalks()
        harvesterDefinitions +=  "}"
        self.saveHarvestDefinition(harvesterDefinitions)

    def describeCrossWalks(self):
        notFirst = False
        xsltCrossWalks = ',\n"xsl_file":['
        for files in os.listdir(myconfig.run_dir + '/xslt'):
            if files.endswith(".xsl"):
                if notFirst:
                    xsltCrossWalks += ','
                notFirst = True
                xsltCrossWalks +=  '"%s"' %(files)
        return xsltCrossWalks + ']'

    def saveHarvestDefinition(self, harvesterDefinitions):
        #save definition to file
        file = open(self.__harvesterDefinitionFile, "w+")
        file.write(harvesterDefinitions)
        file.close()
        #and add to the database
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM configs WHERE `key`='harvester_methods';")
        if(cur.rowcount > 0):
            cur.execute("UPDATE configs set `value`='%s' where `key`='harvester_methods';" %(harvesterDefinitions.replace("'", "\\\'")))
        else:
            cur.execute("INSERT INTO configs (`value`, `key`) VALUES ('%s','%s');" %(harvesterDefinitions.replace("'", "\\\'"), 'harvester_methods'))
        conn.commit()
        cur.close()
        del cur
        conn.close()

    def reportToRegistry(self):
        statusDict = {'last_report_timestamp' : time.time(),
                    'start_up_time' : self.__startUpTime,
                    'harvests_running' : str(len(self.__runningHarvests)),
                    'harvests_queued' : str(len(self.__harvestRequests)),
                    'total_harvests_started' : str(self.__harvestStarted),
                    'harvest_completed' : str(self.__harvestCompleted),
                    'harvest_stopped' : str(self.__harvestStopped),
                    'harvest_errored' : str(self.__harvestErrored),
                    }
        conn = self.__database.getConnection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM configs WHERE `key`='harvester_status';")
        if(cur.rowcount > 0):
            cur.execute("UPDATE configs set `value`='%s' where `key`='harvester_status';" %(json.dumps(statusDict).replace("'", "\\\'")))
        else:
            cur.execute("INSERT INTO configs (`value`, `type`, `key`) VALUES ('%s','%s','%s');" %(json.dumps(statusDict).replace("'", "\\\'"), 'json', 'harvester_status'))
        conn.commit()
        cur.close()
        del cur
        conn.close()


    def setupEnv(self):
        if not os.path.exists(myconfig.data_store_path):
            os.makedirs(myconfig.data_store_path)
            os.chmod(myconfig.data_store_path, 0o777)
        if not os.path.exists(myconfig.log_dir):
            os.makedirs(myconfig.log_dir)
            os.chmod(myconfig.log_dir, 0o777)


    def run(self):
        self.__startUpTime = time.time()
        self.__lastLogCount = 99
        self.__database = self.__DataBase()
        self.__logger = self.__Logger()
        self.__harvesterDefinitionFile = myconfig.run_dir + "harvester_definition.json"
        self.setupEnv()
        self.describeModules()
        self.fixBrokenHarvestRequests()
        self.__logger.logMessage("\n\nSTARTING HARVESTER...")
        atexit.register(self.shutDown)
        try:
            while True:
                self.manageHarvests()
                time.sleep(myconfig.polling_frequency)
        except (KeyboardInterrupt, SystemExit):
            self.__logger.logMessage("\n\nSTOPPING...")
            self.shutDown()
        except Exception as e:
            print("error %r" %(e))
            pass


    def printLogs(self, hCounter):
        if(self.__lastLogCounter > 0 or hCounter > 0):
            self.__lastLogCounter = hCounter
            self.__logger.logMessage('RUNNING: %s WAITING: %s' %(str(len(self.__runningHarvests)), str(len(self.__harvestRequests))))
            self.__logger.logMessage('R...')
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo())
            self.__logger.logMessage('W...')
            for harvestID in list(self.__harvestRequests):
                harvestReq = self.__harvestRequests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo())
            self.__logger.logMessage('______________________________________________________________________________________________')



    def shutDown(self):
        self.__logger.logMessage("SHUTTING DOWN...")
        try:
            if len(self.__runningHarvests) > 0:
                for harvestID in list(self.__runningHarvests):
                    harvestReq = self.__runningHarvests[harvestID]
                    #if harvestReq.getStatus() != "COMPLETED" and not(harvestReq.getStatus().startswith("STOPPED")):
                    harvestReq.rescheduleHarvest()
                    del harvestReq
                    del self.__runningHarvests[harvestID]
        except Exception as e:
            print("error %r" %(e))





if __name__ == '__main__':
    sys.path.append(myconfig.run_dir + '/harvest_handlers')
    hd = HarvesterDaemon(myconfig.run_dir + '/daemon.pid')
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            hd.start() #hd.run() for running in front
        elif 'stop' == sys.argv[1]:
            hd.stop()
        elif 'restart' == sys.argv[1]:
            hd.restart()
        elif 'status' == sys.argv[1]:
            hd.status()
        else:
            print ("Unknown command")
            sys.exit(2)
        sys.exit(0)
    else:
        print ("Usage: {} start|stop|restart".format(sys.argv[0]))
        sys.exit(2)


