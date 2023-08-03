import random

import myconfig
import json
import unittest
import responses

import requests
import io, myconfig

from utils.SlackUtils import SlackUtils

"""
https://dad-jokes-by-api-ninjas.p.rapidapi.com/v1/dadjokes
free and clean (3000 p/m)
"""
def get_joke_message():
    url = "https://dad-jokes-by-api-ninjas.p.rapidapi.com/v1/dadjokes"

    if not(hasattr(myconfig, "X_RapidAPI_Key")) or myconfig.X_RapidAPI_Key.strip() == '':
        return "No X_RapidAPI_Key, No Jokes for you!"

    headers = {
        "X-RapidAPI-Key": myconfig.X_RapidAPI_Key,
        "X-RapidAPI-Host": "dad-jokes-by-api-ninjas.p.rapidapi.com"
    }

    faces = [":troll:", ":ninja:", ":thinking_face:", ":zany_face:", ":woozy_face:", ":face_with_peeking_eye:", ":dotted_line_face:",
             ":face_with_rolling_eyes:", ":cat:", ":clown_face:", ":shrug:",
             ":face_palm:"]
    try:
        response = requests.get(url, headers=headers)
        joke = response.json()
        return random.choice(faces) + "\n" + joke[0]['joke'] + "\n" + random.choice(faces)
    except Exception as e:
        print(e)
        return "No Joke for you!"


class test_slack_utils(unittest.TestCase):

    def test_post_message(self):
        slack_util = SlackUtils(myconfig.slack_channel_webhook_url, myconfig.slack_channel_id)
        message = get_joke_message()
        response = slack_util.post_message("Unit-Test Debug msg:" + message, 6, "DEBUG")
        self.assertTrue(response == 200)
        message = get_joke_message()
        response = slack_util.post_message("Unit-Test Info msg:" + message, 6, "INFO")
        self.assertTrue(response == 200)
        message = get_joke_message()
        response = slack_util.post_message("Unit-Test Error msg:" + message, 6, "ERROR")
        self.assertTrue(response == 200)
