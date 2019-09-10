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
            ds_id = request.args.get('ds_id', type=int)
            if ds_id is None or ds_id < 0:
                return "ds_id is required and must be a positive integer"
            else:
                return jsonify(daemon.runHarvestById(ds_id))
        except Exception as e:
            print(e)
            return

    @app.route('/run_batch', methods=['GET'])
    def runBatch():
        try:
            ds_id = request.args.get('ds_id', type=int)
            batch_id = request.args.get('batch_id')
            if ds_id is None:
                return "ds_id is required and must be a positive integer"
            elif batch_id is None:
                return "batch_id required"
            else:
                return jsonify(daemon.runBatch(ds_id, batch_id))
        except Exception as e:
            print(e)
            return
    return app
