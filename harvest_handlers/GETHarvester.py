from Harvester import *

class GETHarvester(Harvester):
    """
       {
            "id": "GETHarvester",
            "title": "GET Harvester",
            "description": "simple GET Harvester to fetch a single metadata document",
            "params": [
                {"name": "uri", "required": "true"},
                {"name": "crosswalk", "required": "false"},
                {"name": "xsl_file", "required": "false"}
            ]
      }
    """
    def harvest(self):
        self.getHarvestData()
        self.storeHarvestData()
        self.runCrossWalk()
        self.postHarvestData()
        self.finishHarvest()
