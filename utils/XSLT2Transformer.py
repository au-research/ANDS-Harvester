import subprocess
import urllib.parse

import myconfig

class XSLT2Transformer:
    """
    XSLT 2.0 transformer run in java
    Since there are no XSLT 2.0 transformers in Python
    """

    __xsl = None
    __outfile = None
    __inputFile = None
    __params = ''

    def __init__(self, transformerConfig):
        """
        the transformerConfig is a dictionary that contains a mix of values
        the required ones are
        'xsl':the path to the xsl file
        'outFile': the path where the result is saved
        'inFile': the source XML document
        all other key value pairs are passed as parameters to the XSLT transform
        eg: 'originatingSource':'ARDC Harvester'
        :param transformerConfig:
        :type a dict containig transformer configurations:
        """
        for key, value in transformerConfig.items():
            if key == 'xsl':
                self.__xsl = value
            elif key =='outFile':
                self.__outfile = value
            elif key == 'inFile':
                self.__inputFile = value
            else:
                self.__params += " " + key + "='" + self.clean_param(value) + "'"


    def transform(self):
        """
        XSLT transformer is using java and Saxon XSLT 2.0 transformer running in a subprocess
        to
        """
        shellCommand = myconfig.java_home + " "
        shellCommand += " -cp " + myconfig.saxon_jar + " net.sf.saxon.Transform"
        shellCommand += " -o " + self.__outfile
        shellCommand += " " + self.__inputFile
        shellCommand += " " + self.__xsl
        if self.__params != '':
            shellCommand += self.__params
        subprocess.check_output(shellCommand, stderr=subprocess.STDOUT, shell=True)
        subprocess.call(shellCommand, shell=True)

    def clean_param(self, value):
        new_value = urllib.parse.quote_plus(value)
        return new_value