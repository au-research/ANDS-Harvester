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

    def harvest(self):
        self.getHarvestData()
        self.storeHarvestData()




