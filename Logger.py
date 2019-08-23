# harvester daemon script in python
# for ANDS registry
# Author: u4187959
# created 12/05/2014
#

from datetime import datetime
import os
import myconfig

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