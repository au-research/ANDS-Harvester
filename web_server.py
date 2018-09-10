from flask import Flask, jsonify, request


def new(daemon):
    """
    Returns a new Flask instance for a Daemon
    Daemon must implements the info function

    :param daemon:
    :return: Flask
    """
    app = Flask(__name__)

    @app.route('/', methods=['GET'])
    def info():
        return jsonify(daemon.info())

    return app
