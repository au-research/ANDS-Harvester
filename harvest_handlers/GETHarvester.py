from Harvester import *

class GETHarvester(Harvester):
    """
       {
            "id": "GETHarvester",
            "title": "GET Harvester",
            "description": "simple GET Harvester to fetch a single metadata document in XML or JSON format",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    def harvest(self):
        """
        The GET Harvester doesn't override any of the Harvester's methods
        it retrieves the data from the given url
        stores it / crosswalks it (if needed)
        and finishes the harvest
        """
        self.setupdirs()
        self.data = None
        self.updateHarvestRequest()
        self.setUpCrosswalk()
        self.getHarvestData()
        self.pageCount = 1
        self.storeHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()
