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
        self.cleanPreviousHarvestRecords()
        self.getHarvestData()
        self.storeHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()
