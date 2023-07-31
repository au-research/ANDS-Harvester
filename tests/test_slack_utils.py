import myconfig
import json
import unittest
import responses

import requests
import io, myconfig

from utils.SlackUtils import SlackUtils

"""
https://rapidapi.com/almann/api/dad-jokes7/
free (10 pd)
"""
def get_joke_message():
    url = "https://dad-jokes7.p.rapidapi.com/dad-jokes/random"

    if not(hasattr(myconfig, "X_RapidAPI_Key")) or myconfig.X_RapidAPI_Key.strip() == '':
        return "No X_RapidAPI_Key, No Jokes for you!"

    headers = {
        "X-RapidAPI-Key": myconfig.X_RapidAPI_Key,
        "X-RapidAPI-Host": "dad-jokes7.p.rapidapi.com"
    }

    try:
        response = requests.get(url, headers=headers)
        joke = response.json()
        return "\n" + joke['joke'] + ":zany_face:"
    except Exception:
        return "No Joke for you!"


class test_slack_utils(unittest.TestCase):

    def test_post_message(self):
        slackutil = SlackUtils(myconfig.slack_channel_webhook_url, myconfig.slack_channel_id)
        message = get_joke_message()
        response = slackutil.post_message("Unit-Test Debug msg:" + message, 6, "DEBUG")
        self.assertTrue(response == 200)
        message = get_joke_message()
        response = slackutil.post_message("Unit-Test Info msg:" + message, 6, "INFO")
        self.assertTrue(response == 200)
        message = get_joke_message()
        response = slackutil.post_message("Unit-Test Error msg:" + message, 6, "ERROR")
        self.assertTrue(response == 200)
