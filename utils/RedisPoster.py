import redis
import myconfig


class RedisPoster:
    poster = False

    def __init__(self):
        if hasattr(myconfig, 'redis_poster_host') and myconfig.redis_poster_host != "":
            self.poster = redis.StrictRedis(host=myconfig.redis_poster_host, port=6379, db=0)

    def postMesage(self, chanel, message):
        if self.poster:
            self.poster.publish(chanel, message)