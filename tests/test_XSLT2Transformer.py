import unittest


from utils.XSLT2Transformer import XSLT2Transformer


class test_XSLT2Transformer(unittest.TestCase):


     def test_clean_param(self):
         harvestInfo_1 = {}
         harvestInfo_1['title'] = "The Datasource's Title"

         cleaned_param = XSLT2Transformer.clean_param(self, harvestInfo_1['title'])

         self.assertEqual("The+Datasource%27s+Title", cleaned_param)

     if __name__ == '__main__':
         unittest.main()