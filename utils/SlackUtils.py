import requests
from requests.adapters import HTTPAdapter
import urllib3
import myconfig

class SlackUtils:

    webhook_url = None
    channel_id = None

    def __init__(self, webhook_url, channel_id):
        self.retryCount = 3
        urllib3.disable_warnings()
        self.webhook_url = webhook_url
        self.channel_id = channel_id


    def post_message(self, text, data_source_id, message_type='INFO'):
        """
        actually this method just send a GET request
        this is the "agreed" communication between the harvester and the registry
        :return:
        :rtype:
        """
        if not self.webhook_url:
            return
        colour = "#00FF00"
        if message_type == 'ERROR':
            colour = "#FF0000"
        http_adapter = HTTPAdapter(max_retries=self.retryCount)
        session = requests.Session()
        session.mount(self.webhook_url, http_adapter)
        data = {
                "channel": self.channel_id ,
                "text": myconfig.slack_harvester_name + " " + message_type,
                "attachments": [
                    {
                        "text": text,
                        "color": colour
                    },
                    {
                        "type": "mrkdwn",
                        "text": "View the <"+ myconfig.slack_registry_datasource_view_url + str(data_source_id) + "|DataSource> for more details",
                        "color": colour
                    }
                ]
            }
        try:
            header = {'User-Agent': 'ARDC Harvester'}
            response = session.post(self.webhook_url, json=data, headers=header, verify=False)
            response.raise_for_status()
            session.close()
        except Exception as e:
            session.close()
            pass