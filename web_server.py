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

    @app.route('/run_harvest', methods=['GET'])
    def runHarvest():
        try:
            harvest_id = request.args.get('harvest_id')
            return jsonify(daemon.runHarvestById(harvest_id))
        except Exception as e:
            pass

    @app.route('/run_crosswalk', methods=['GET'])
    def rerunHarvestFromCroswalk():
        try:
            harvest_id = int(request.args.get('harvest_id'))
            batch_id = request.args.get('batch_id')
            return jsonify(daemon.rerunHarvestFromCroswalk(harvest_id, batch_id))
        except Exception as e:
            print(e)
            pass
    return app
