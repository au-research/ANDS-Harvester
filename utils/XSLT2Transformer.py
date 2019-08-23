import subprocess
import myconfig

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