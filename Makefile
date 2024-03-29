ENV_NAME?=venv
GLOBAL_PYTHON=/usr/bin/python3.6
PIP=${ENV_NAME}/bin/pip
PYTHON=${ENV_NAME}/bin/python3.6
clean:
	rm -rf ${ENV_NAME}
	rm -rf __pycache__

build:
	${GLOBAL_PYTHON} -m venv ${ENV_NAME}
	${PYTHON} -m pip install --upgrade pip
	${PIP} install -r requirements.txt

run:
	${PYTHON} task_processor_daemon.py run

test:
	${ENV_NAME}/bin/nose2 -c nose2.cfg -v

package: clean
	zip -9 -r artifact.zip . -x '/*.git/*'
