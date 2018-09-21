# harvester daemon script in python
# for ANDS registry
# Author: u4187959
# created 12/05/2014
#

from datetime import datetime
import sys, os, time, atexit
from signal import SIGTERM, SIGINT
import pymysql
import myconfig
import time
import Harvester
import string
import json
import threading
from harvest_handlers import *
import web_server

class Logger:
    __fileName = False
    __file = False
    __current_log_time = False
    logLevels = {'ERROR':100,'INFO':50,'DEBUG':10}
    __logLevel = 100
    def __init__(self):
        self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
        self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"
        self.__logLevel = self.logLevels[myconfig.log_level]
        self.logMessage("loglevel set to %s:%s" %(str(self.__logLevel), myconfig.log_level), myconfig.log_level)

    def logMessage(self, message, logLevel='DEBUG'):
        if (self.logLevels[logLevel] >= self.__logLevel):
            self.rotateLogFile()
            self.__file = open(self.__fileName, "a", 0o775)
            os.chmod(self.__fileName, 0o775)
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

    class __Logger:
        __fileName = False
        __file = False
        __current_log_time = False
        logLevels = {'ERROR':100,'INFO':50,'DEBUG':10}
        __logLevel = 100
        def __init__(self):
            self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
            self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"
            self.__logLevel = self.logLevels[myconfig.log_level]
            self.logMessage("loglevel set to %s:%s" %(str(self.__logLevel), myconfig.log_level), myconfig.log_level)

        def logMessage(self, message, logLevel='DEBUG'):
            if(self.logLevels[logLevel] >= self.__logLevel):
                self.rotateLogFile()
                self.__file = open(self.__fileName, "a", 0o777)
                self.__file.write(logLevel + ": " + message + " %s"  % datetime.now() + "\n")
                self.__file.close()

        def rotateLogFile(self):
            if(self.__current_log_time != datetime.now().strftime("%Y-%m-%d")):
                self.__current_log_time = datetime.now().strftime("%Y-%m-%d")
                self.__fileName = myconfig.log_dir + os.sep + self.__current_log_time + ".log"
                number_to_keep = 14
                if len(os.listdir(myconfig.log_dir)) > number_to_keep:
                    the_files = self.listdir_fullpath(myconfig.log_dir)
                    the_files.sort(key=os.path.getmtime, reverse=True)
                    for i in range(number_to_keep, len(the_files)):
                        try:
                            if os.path.isfile(the_files[i]):
                                os.unlink(the_files[i])
                            else:
                                self.deleteDirectory(the_files[i])
                                os.rmdir(the_files[i])
                        except Exception as e:
                            self.logger.logMessage(e, "ERROR")


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
                    self.logMessage(e, "ERROR")

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
                self.__connection = pymysql.connect(host=self.__host, user=self.__user,
                                                    passwd = self.__passwd, db = self.__db)
            except:
                e = sys.exc_info()[1]
                raise RuntimeError("Database Exception %s" %(e))
            return self.__connection

    def handleException(self, harvestId, exception):
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
        self.__logger.logMessage("DataSource ID: %s, harvest_id: %s " %(str(dataSourceId),str(harvestID)), "INFO")
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

        try:
            harvester_module = __import__(harvestInfo['harvest_method'], globals={}, locals={}, fromlist=[], level=0)

            class_ = getattr(harvester_module, harvestInfo['harvest_method'])
            myHarvester = class_(harvestInfo, self.__logger, self.__database)
            self.__harvestRequests[harvestID] = myHarvester

        except ImportError as e:
            self.handleException(harvestID, e)


    def manageHarvests(self):
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
                    self.__logger.logMessage("harvestID %s already scheduled" % str(harvestID), "DEBUG")


    def checkForHarvestRequests(self, limit):
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

    def fixBrokenHarvestRequests(self):
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
        if not os.path.exists(myconfig.data_store_path):
            os.makedirs(myconfig.data_store_path)
            os.chmod(myconfig.data_store_path, 0o775)
        if not os.path.exists(myconfig.log_dir):
            os.makedirs(myconfig.log_dir)
            os.chmod(myconfig.log_dir, 0o775)

    def run(self):
        self.__startUpTime = time.time()
        self.__lastLogCount = 99
        self.__database = self.__DataBase()
        self.__logger = self.__Logger()
        self.__harvesterDefinitionFile = myconfig.run_dir + os.sep + "harvester_definition.json"
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
        if(self.__lastLogCounter > 0 or hCounter > 0):
            self.__lastLogCounter = hCounter
            self.__logger.logMessage('RUNNING: %s WAITING: %s' %(str(len(self.__runningHarvests)), str(len(self.__harvestRequests))), "DEBUG")
            self.__logger.logMessage('RUNNING', "DEBUG")
            for harvestID in list(self.__runningHarvests):
                harvestReq = self.__runningHarvests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo(), "DEBUG")
            self.__logger.logMessage('WAITING', "DEBUG")
            for harvestID in list(self.__harvestRequests):
                harvestReq = self.__harvestRequests[harvestID]
                self.__logger.logMessage(harvestReq.getInfo(), "DEBUG")
            self.__logger.logMessage('______________________________________________________________________________________________', "DEBUG")



    def shutDown(self):
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


