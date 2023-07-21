import myconfig
import json
import unittest
import responses

import requests
import io, myconfig

from utils.SlackUtils import SlackUtils

class test_slack_utils(unittest.TestCase):


    def test_post_message(self):
        slackutil = SlackUtils(myconfig.slack_channel_webhook_url, myconfig.slack_channel_id)
        slackutil.post_message("Info message", 6 , "INFO")
        slackutil.post_message("Error message form harvester", 6, "ERROR")
