import redis
import myconfig


class RedisPoster:
    poster = False

    def __init__(self):
        if hasattr(myconfig, 'redis_poster_host') and myconfig.redis_poster_host != "":
            self.poster = redis.StrictRedis(host=myconfig.redis_poster_host, port=6379, db=0)

    def postMesage(self, chanel, message):
        """
        post the message to 'datasource.' + 'data_source_id' + '.harvest' channel
        :param chanel:
        :type chanel:
        :param message:
        :type message:
        """
        if self.poster:
            self.poster.publish(chanel, message)