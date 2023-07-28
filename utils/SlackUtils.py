import requests
from requests.adapters import HTTPAdapter
import urllib3
import myconfig
import sys


class SlackUtils:
    webhook_url = None
    channel_id = None
    logLevels = {'ERROR': 100, 'INFO': 50, 'DEBUG': 10}
    logLevel = 100

    def __init__(self, webhook_url, channel_id):
        self.retryCount = 3
        urllib3.disable_warnings()
        self.webhook_url = webhook_url
        self.channel_id = channel_id
        self.logLevel = self.logLevels[myconfig.slack_channel_notification_level]

    def post_message(self, text, data_source_id, message_type='INFO'):
        """
        Send Messages to the configured Slack channel
        """
        if not self.webhook_url:
            return
        if self.logLevels[message_type] < self.logLevel:
            return
        colour = "#00AA00"
        if message_type == 'ERROR':
            colour = "#AA0000"
        if message_type == 'DEBUG':
            colour = "#0000AA"
        http_adapter = HTTPAdapter(max_retries=self.retryCount)
        session = requests.Session()
        session.mount(self.webhook_url, http_adapter)
        data = {
            "channel": self.channel_id,
            "text": myconfig.slack_app_name + " " + message_type,
            "attachments": [
                {
                    "text": text,
                    "color": colour
                },
                {
                    "type": "mrkdwn",
                    "text": "View the <" + myconfig.slack_registry_datasource_view_url + str(data_source_id)
                            + "|DataSource> for more details",
                    "color": colour
                }
            ]
        }
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.post(self.webhook_url, json=data, headers=header, verify=False)
            response.raise_for_status()
            session.close()
            return response.status_code
        except Exception:
            e = sys.exc_info()[1]
            session.close()
            return repr(e)
