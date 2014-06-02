from Harvester import *

class GETHarvester(Harvester):
    """
       {'harvester_method': {
        'id': 'GETHarvester',
        'title': 'simple GET Harvester to fetch a single metadata document',
        'params': [
            {'name': 'url', 'required': 'true'},
            {'name': 'crosswalk', 'required': 'false'}
        ]
      }
    """
    def harvest(self):
        self.getHarvestData()
        self.storeHarvestData()
        self.finishHarvest()
