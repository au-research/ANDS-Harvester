import subprocess
import myconfig

class XSLT2Transformer:

    #XSLT 2.0 transformer run in java
    __xsl = None
    __outfile = None
    __inputFile = None
    __params = ''

    def __init__(self, transformerConfig):
        for key, value in transformerConfig.items():
            if key == 'xsl':
                self.__xsl = value
            elif key =='outFile':
                self.__outfile = value
            elif key == 'inFile':
                self.__inputFile = value
            else:
                self.__params += " " + key + "='" + value + "'"


    def transform(self):
        shellCommand = myconfig.java_home + " "
        shellCommand += " -cp " + myconfig.saxon_jar + " net.sf.saxon.Transform"
        shellCommand += " -o " + self.__outfile
        shellCommand += " " + self.__inputFile
        shellCommand += " " + self.__xsl
        if self.__params != '':
            shellCommand += self.__params
        subprocess.check_output(shellCommand, stderr=subprocess.STDOUT, shell=True)
        subprocess.call(shellCommand, shell=True)