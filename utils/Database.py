import pymysql
import pymysql.cursors
import myconfig
import sys

class DataBase:
    __connection = None
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
        self.__port = myconfig.db_port

    def getConnection(self):
        #if self.__connection is None:
        #print("getConnection")
        try:
            self.__connection = pymysql.connect(host=self.__host,
                                                user=self.__user,
                                                passwd=self.__passwd,
                                                db=self.__db,
                                                port=self.__port)
        except:
            e = sys.exc_info()[1]
            raise RuntimeError("Database Exception %s" % (e))
        return self.__connection
