from Harvester import *

class CSWHarvester(Harvester):
    """
        {
            "id": "CSWHarvester",
            "title": "CSW Harvester",
            "description": "CSW Harvester to fetch metadata using Catalog Service for the Web protocol",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "outputSchema", "required": "true"}
            ]
        }
    """

    __outputSchema = False
    retryCount = 0
    listSize = 10
    def harvest(self):
        self.getHarvestData()
        self.storeHarvestData()



####http://e-atlas.org.au/geonetwork/srv/en/csw
#?request=GetRecords
#&service=CSW
#&version=2.0.2
#&namespace=xmlns(csw=http://www.opengis.net/cat/csw)
#&resultType=results
#&outputSchema=http://www.isotc211.org/2005/gmd
#&outputFormat=application/xml
#&maxRecords=10
#&typeNames=csw:Record
#&elementSetName=full
#&constraintLanguage=CQL_TEXT
#&constraint_language_version=1.1.0###
