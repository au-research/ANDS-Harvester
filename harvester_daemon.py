# harvester daemon script in python
# for ARDC registry
# Author: u4187959
# created 12/05/2014
#
from gevent import monkey
monkey.patch_all()

from datetime import datetime
import sys, os, time, atexit
from signal import SIGTERM, SIGINT
import pymysql
import myconfig
from utils import Logger
import time
import Harvester
import string
import json
import threading
from harvest_handlers import *
from utils.Logger import Logger as MyLogger
from utils.Database import DataBase as MyDataBase
import web_server


class Daemon(object):
    """
    Subclass Daemon class and override the run() method.
    """
    def __init__(self, pidfile, stdin='/dev/null', stdout='/dev/null', stderr='/dev/null'):
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.pidfile = pidfile
        self.__logger = MyLogger()

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

        self.__logger.logMessage('deamon going to background, PID: {}'.format(os.getpid()), "INFO")

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
        atexit.register(self.delpid)

    def delpid(self):
        self.__logger.logMessage("\n\nDELETING PID FILE...", "INFO")
        os.remove(self.pidfile)

    def start(self):
        """
        Start daemon.
        """
        # Check pidfile to see if the daemon already runs.
        try:
            pf = open(self.pidfile, 'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError as e:
            pid = None

        if pid:
            message = "Pidfile {} already exist. Daemon already running?\n".format(self.pidfile)
            message += "If you're sure that the harvester is not running delete the pid file and try again!\n"
            sys.stderr.write(message)
            sys.exit(1)

        # Start daemon.
        self.__logger.logMessage("\n\nSTARTING HARVESTER_DAEMON...", "INFO")
        self.daemonize()
        try:
            atexit.register(Daemon.shutDown)
            self.run()
        except (KeyboardInterrupt, SystemExit):
            self.shutDown()
            self.__logger.logMessage("\n\nSTOPPING...", "INFO")


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
        self.__logger.logMessage("\nSTOPPING HARVESTER_DAEMON...", "INFO")

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
            os.kill(pid, SIGINT)
            self.__logger.logMessage("\nKILLING %s..." %str(pid))
            time.sleep(1)
        except OSError as e:
            print(str(e))
            sys.exit(1)

        try:
            if os.path.exists(self.pidfile):
                self.__logger.logMessage("\nDELETING PIDFILE %s..." %self.pidfile, "INFO")
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

    def shutDown(self):
        self.__logger.logMessage("\nSHUTTING DOWN ...", "INFO")

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


    def handleException(self, harvestId, exception):
        """
        Sets the harvest's status to STOPPED and updates the given record in the database
        :param harvestId:
        :type harvestId:
        :param exception:
        :type exception:
        :return:
        :rtype:
        """
        harvesterStatus = 'STOPPED'
        self.__harvestErrored += 1
        eMessage = repr(exception).replace("'", "").replace('"', "")
        attempts = 0
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute("UPDATE %s SET `status` ='%s', `message` = '%s' "
                            "where `harvest_id` = %s" %(myconfig.harvest_table, harvesterStatus, eMessage, str(harvestId)))
                conn.commit()
                cur.close()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(handleException) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")
        return


    def addHarvestRequest(self, harvestID, dataSourceId, nextRun, lastRun, mode, batchNumber):
        """
        extracts metadata about the given Datasource ad based on the harvest_method it instantiate a harvest Handler
        adds a new harvest Handler to the self.__harvestRequests[harvestID] list

        :param harvestID:
        :type harvestID:
        :param dataSourceId:
        :type dataSourceId:
        :param nextRun:
        :type nextRun:
        :param lastRun:
        :type lastRun:
        :param mode:
        :type mode:
        :param batchNumber:
        :type batchNumber:
        :return:
        :rtype:
        """
        harvestInfo = {}
        attempts = 0
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                harvestInfo['crosswalk'] = None
                harvestInfo['xsl_file'] = None
                harvestInfo['last_harvest_run_date'] = ''
                cur.execute("SELECT * FROM data_sources where `data_source_id` =%s;" %(str(dataSourceId)))
                for r in cur:
                    harvestInfo['data_source_id'] = r[0]
                    harvestInfo['data_source_slug'] = r[1]
                    harvestInfo['data_source_slug'] = r[2]
                    harvestInfo['title'] = r[3]
                cur.execute("SELECT `attribute`, `value` FROM data_source_attributes "
                            "where `attribute` in(%s) and `data_source_id` =%s;"
                            %(myconfig.harvester_specific_datasource_attributes, str(dataSourceId)))
                for r in cur:
                    harvestInfo[r[0]] = r[1]
                harvestInfo['mode'] = mode
                harvestInfo['response_url'] = myconfig.response_url
                harvestInfo['data_store_path'] = myconfig.data_store_path
                harvestInfo['harvest_id'] = harvestID
                harvestInfo['batch_number'] = batchNumber
                harvestInfo['from_date'] = lastRun
                harvestInfo['until_date'] = nextRun
                cur.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(addHarvestRequest) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")
                if attempts == 3:
                    return
        self.__logger.logMessage("DataSource ID: %s, harvest_id: %s HarvestMethod:%s" %
                                 (str(dataSourceId), str(harvestID), harvestInfo['harvest_method']), "INFO")
        try:
            harvester_module = __import__(harvestInfo['harvest_method'], globals={}, locals={}, fromlist=[], level=0)

            class_ = getattr(harvester_module, harvestInfo['harvest_method'])
            myHarvester = class_(harvestInfo)
            self.__harvestRequests[harvestID] = myHarvester
        except ImportError as e:
            self.handleException(harvestID, e)
        return harvestInfo

    def manageHarvests(self):
        """
        Checks for Harvest Request
        If there are running harvest check if their status is changed by the Registry eg STOPPED
        if there are harvest requests and there are free thread spaces then start the queued harvests until reached maxSimHarvests
        """
        # self.reportToRegistry()
        if len(self.__runningHarvests) < self.__maxSimHarvestRun:
            self.checkForHarvestRequests(self.__maxSimHarvestRun - len(self.__runningHarvests))
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
                    # if harvest was stopped by the registry
                    if harvestReq.getStatus() == "STOPPED":
                        del self.__harvestRequests[harvestID]
                    # can use harvest_id to stop multiple harvest into same datasource
                    if harvestReq.getStatus() == "WAITING" and harvestID not in self.__runningHarvests.keys():
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
                    self.__logger.logMessage("harvestID %s already scheduled" % str(harvestID), "DEBUG")


    def checkForHarvestRequests(self, limit):
        """
        checks if there are SCHEDULED harvests that are in the past
        and adds them to the Queue by calling addHarvestRequest
        :param limit:
        :type limit:
        """
        attempts = 0
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute("SELECT * FROM "+ myconfig.harvest_table +" WHERE `status` = "
                            "'SCHEDULED' AND ('next_run' is null OR `next_run` <=timestamp('" +
                            str(datetime.now()) + "')) ORDER BY `next_run` LIMIT "+ str(limit) +";" )
                if(cur.rowcount > 0):
                    self.__logger.logMessage("Scheduling Harvest Count:%s" %str(cur.rowcount), "DEBUG")
                    for r in cur:
                        self.addHarvestRequest(r[0],r[1],r[4],r[5],r[6],r[7])
                cur.close()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(checkForHarvestRequests) %s, , limit %s, Retry: %d' % (str(repr(e)), str(limit), attempts), "ERROR")

    def runHarvestById(self, ds_id):
        """
        This method is implemented by a service endpoint for future usage
        it adds a harvest request for the given datasource id (if there is an entry in the harvests table
        :param ds_id:
        :type ds_id:
        :return:
        :rtype:
        """
        attempts = 0
        harvestInfo = {}
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute(
                    "UPDATE " + myconfig.harvest_table + " SET `status`='SCHEDULED' WHERE `data_source_id` = " + str(ds_id) + ";")
                conn.commit()
                cur.execute("SELECT * FROM " + myconfig.harvest_table + " WHERE `data_source_id` = " + str(ds_id) + ";")
                if cur.rowcount > 0:
                    self.__logger.logMessage("Adding Harvest by data_source_id :%s" % str(ds_id), "DEBUG")
                    for r in cur:
                        harvestInfo = self.addHarvestRequest(r[0],r[1],r[4],r[5],r[6],r[7])
                else:
                    self.__logger.logMessage("Harvest for data_source_id :%s doesn't exist" %str(ds_id), "DEBUG")
                cur.close()
                del cur
                conn.close()
                return harvestInfo
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(Adding Harvest by DS_ID) %s, , ds_id %s, Retry: %d' % (str(repr(e)), str(ds_id), attempts), "ERROR")

    def runBatch(self, ds_id, batch_id):
        """
        This method is implemented by a service endpoint for future usage
        It finds a harvest request in the database for the given datasource id
        locates the content by the given batch id
        instantiate the harvest handler and runs the harvest from the crosswalk task
        no actual harvest is performed
        :param ds_id:
        :type ds_id:
        :param batch_id:
        :type batch_id:
        :return:
        :rtype:
        """
        attempts = 0
        harvestInfo = {}
        if not os.path.exists(myconfig.data_store_path + str(ds_id) + os.sep + batch_id):
            harvestInfo["ERROR"] = "content belonging to the given batch_id can not be located"
            return harvestInfo
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute(
                    "UPDATE " + myconfig.harvest_table + " SET `status`='WAITING' WHERE `data_source_id` = " + str(ds_id) + ";")
                conn.commit()
                cur.execute("SELECT * FROM " + myconfig.harvest_table + " WHERE `data_source_id` = " + str(ds_id) + ";")
                if cur.rowcount > 0:
                    self.__logger.logMessage("Adding Harvest by data_source_id :%s" %str(ds_id), "DEBUG")
                    for r in cur:
                        harvest_id = r[0]
                        harvestInfo = self.addHarvestRequest(r[0], r[1], r[4], r[5], r[6], batch_id)
                        harvestReq = self.__harvestRequests.pop(harvest_id)
                        self.__runningHarvests[harvest_id] = harvestReq
                        t = threading.Thread(target=harvestReq.crosswalk)
                        self.__running_threads[harvest_id] = t
                        t.start()
                        self.__harvestStarted = self.__harvestStarted + 1
                else:
                    self.__logger.logMessage("Harvest for data_source_id :%s doesn't exist" %str(ds_id), "DEBUG")
                cur.close()
                del cur
                conn.close()
                return harvestInfo
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(Adding Harvest (Crosswalk only) by data_source_id) %s, , ds_id %s, Retry: %d' % (str(repr(e)), str(ds_id), attempts),
                    "ERROR")


    def fixBrokenHarvestRequests(self):
        """
        This method is called the time the harvester daemon is stated
        it check if there are entries in the database for "running" (ghost) Harvests
        if there are any it sets their status to SCHEDULED so they can start again from start
        """
        attempts = 0
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute("SELECT count(*) FROM "+ myconfig.harvest_table +" WHERE `status`='HARVESTING' or `status`='WAITING'")
                result = cur.fetchone()
                if result[0] > 0:
                    self.__logger.logMessage("\nFOUND %s BROKEN HARVESTS\nRESCHEDULING...\n" %(str(result[0])))
                cur.execute("UPDATE "+ myconfig.harvest_table +" SET `status`='SCHEDULED' where `status`='HARVESTING' or `status`='WAITING'")
                conn.commit()
                cur.close()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(fixBrokenHarvestRequests) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")

    def describeModules(self):
        """
        creates a JSON representation for the set of harvest handlers

        """
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
        harvesterDefinitions +=  "]}}"
        self.saveHarvestDefinition(harvesterDefinitions)

    def saveHarvestDefinition(self, harvesterDefinitions):
        """
        stores the harvest handlers information in the registry's config table
        :param harvesterDefinitions:
        :type harvesterDefinitions:
        """
        #save definition to file
        file = open(self.__harvesterDefinitionFile, "w+")
        file.write(harvesterDefinitions)
        file.close()
        attempts = 0
        while attempts < 3:
            try:
                conn = self.__database.getConnection()
                cur = conn.cursor()
                cur.execute("SELECT * FROM configs WHERE `key`='harvester_methods';")
                if(cur.rowcount > 0):
                    cur.execute("UPDATE configs set `value`='%s' where `key`='harvester_methods';" %(harvesterDefinitions.replace("'", "\\\'")))
                else:
                    cur.execute("INSERT INTO configs (`value`, `key`, `type`) VALUES ('%s','%s', '%s');" %(harvesterDefinitions.replace("'", "\\\'"), 'harvester_methods', 'json'))
                conn.commit()
                cur.close()
                del cur
                conn.close()
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage(
                    '(saveHarvestDefinition) %s, Retry: %d' % (str(repr(e)), attempts), "ERROR")

    def info(self):
        """
        Returns the current information for the harvester daemon
        Used for reporting current status to a web interface

        :return: dict
        """
        start = datetime.fromtimestamp(self.__startUpTime)
        now = datetime.now()
        dtformat = '%Y-%m-%d %H:%M:%S'

        return {
            'running': True,
            'running_since': start.strftime(dtformat),
            'uptime': (now - start).seconds,
            'harvests': {
                'running': len(self.__runningHarvests),
                'queued': len(self.__harvestRequests),
                'started': self.__harvestStarted,
                'completed': self.__harvestCompleted,
                'stopped': self.__harvestStopped,
                'errored': self.__harvestErrored
            }
        }

    def reportToRegistry(self):
        """
        Report it's status to the registry in the form of writing to the database
        R29 deprecates this functionality in favor of local http server

        :return:
        """
        statusDict = {'last_report_timestamp' : time.time(),
                    'start_up_time' : self.__startUpTime,
                    'harvests_running' : str(len(self.__runningHarvests)),
                    'harvests_queued' : str(len(self.__harvestRequests)),
                    'total_harvests_started' : str(self.__harvestStarted),
                    'harvest_completed' : str(self.__harvestCompleted),
                    'harvest_stopped' : str(self.__harvestStopped),
                    'harvest_errored' : str(self.__harvestErrored),
                    }
        attempts = 0
        while attempts < 3:
            try:
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
                self.__logger.logMessage('Reporting to Registry', "DEBUG")
                break
            except Exception as e:
                attempts += 1
                time.sleep(5)
                self.__logger.logMessage('(reportToRegistry) %s, Retry: %d' %(str(repr(e)), attempts), "ERROR")


    def setupEnv(self):
        """
        creates all directories for the harvester
        """
        if not os.path.exists(myconfig.data_dir):
            os.makedirs(myconfig.data_dir)
            os.chmod(myconfig.data_dir, 0o775)
        if not os.path.exists(myconfig.data_store_path):
            os.makedirs(myconfig.data_store_path)
            os.chmod(myconfig.data_store_path, 0o775)
        if not os.path.exists(myconfig.log_dir):
            os.makedirs(myconfig.log_dir)
            os.chmod(myconfig.log_dir, 0o775)

    def run(self):
        """
        starts the harvester daemon as a process in the foreground
        also starts a webservice to listen on 7020
        to receive requests
        """
        self.__startUpTime = time.time()
        self.__lastLogCount = 99
        self.__database = MyDataBase()
        self.__logger = MyLogger()
        self.__harvesterDefinitionFile = myconfig.data_dir + "harvester_definition.json"
        self.setupEnv()
        self.describeModules()
        self.fixBrokenHarvestRequests()
        self.__logger.logMessage("\n\nSTARTING HARVESTER...", "INFO")
        atexit.register(self.shutDown)

        # Starting the web interface as a different thread
        try:
            web_port = getattr(myconfig, 'web_port', 7020)
            web_host = getattr(myconfig, 'web_host', '0.0.0.0')
            http = web_server.new(daemon=self)
            threading.Thread(
                target=http.run,
                kwargs={
                    'host': web_host,
                    'port': web_port,
                    'debug': False
                },
                daemon=True
            ).start()
            self.__logger.logMessage("\n\nWeb Thread started at port %s \n\n" % web_port)
        except Exception as e:
            self.__logger.logMessage("error %r" % e)
            pass

        try:
            while True:
                self.manageHarvests()
                time.sleep(myconfig.polling_frequency)
        except (KeyboardInterrupt, SystemExit):
            self.__logger.logMessage("\n\nSTOPPING...")
            #self.shutDown()
        except Exception as e:
            self.__logger.logMessage("error %r" %(e))
            pass


    def printLogs(self, hCounter):
        """
        only print a log entry if harvests are running
        :param hCounter: number of the currently running harvest handlers
        :type hCounter:
        """
        if(self.__lastLogCounter > 0 or hCounter > 0):
            self.__lastLogCounter = hCounter
            self.__logger.logMessage('RUNNING: %s WAITING: %s' %(str(len(self.__runningHarvests)), str(len(self.__harvestRequests))), "DEBUG")
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo(), "DEBUG")
            self.__logger.logMessage('WAITING', "DEBUG")
            for harvestID in list(self.__harvestRequests):
                harvestReq = self.__harvestRequests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo(), "DEBUG")
            self.__logger.logMessage('______________________________________________________________________________________________', "DEBUG")



    def shutDown(self):
        """
        When the harvester daemon is shut down it will attempt to reschedule currently running harvests
        also prints the currently logged in users (so we know who killed the harvester)
        """
        #self.__logger.logMessage("SHUTTING DOWN...")
        loggedUserMsg = os.popen('who').read()
        self.__logger.logMessage("SHUTTING DOWN...\nLogged In Users:\n%s" %(loggedUserMsg), "DEBUG")
        try:
            if len(self.__runningHarvests) > 0:
                for harvestID in list(self.__runningHarvests):
                    harvestReq = self.__runningHarvests[harvestID]
                    harvestReq.rescheduleHarvest()
                    del harvestReq
                    del self.__runningHarvests[harvestID]
            if os.path.exists(self.pidfile):
                self.__logger.logMessage("\n\nDELETING PIDFILE %s..." %self.pidfile, "DEBUG")
                os.remove(self.pidfile)
        except IOError as e:
            message = str(e) + "\nCan not remove pid file {}".format(self.pidfile)
            self.__logger.logMessage(message)
        except Exception as e:
            self.__logger.logMessage("error %r" %(e), "ERROR")


if __name__ == '__main__':
    sys.path.append(myconfig.run_dir + 'harvest_handlers')
    hd = HarvesterDaemon(myconfig.run_dir + 'daemon.pid')
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            print("Starting Harvester as Daemon")
            hd.start()
        elif 'run' == sys.argv[1]:
            print("Starting Harvester in the foreground")
            hd.run()
        elif 'stop' == sys.argv[1]:
            print("Stopping the Harvester")
            hd.stop()
        elif 'restart' == sys.argv[1]:
            hd.restart()
        elif 'status' == sys.argv[1]:
            hd.status()
        else:
            print("Unknown command")
            sys.exit(2)
        sys.exit(0)
    else:
        print("Usage: {} run|start|stop|restart".format(sys.argv[0]))
        sys.exit(2)


