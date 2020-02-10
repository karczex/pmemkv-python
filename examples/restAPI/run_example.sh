#!/bin/bash

set -x
POOL_PATH=${TEST_PATH:-/dev/shm/pmemkvREST_pool}
APP_DIR=${APP_DIR:-$PWD}
POOL_SIZE=${POOL_SIZE:-1073741824}

assert() {
	echo "${1}"
	if [ "${1}" != "${2}" ]
	then
		echo ""Assertion failed:  \"$1\" not equal"\"$2\""
		exit 1
	fi
}

run_server() {
	PMEMKV_POOL_PATH=$1 python3 pmemkvREST.py &
	echo $!
}

shutdown_server() {
	pid=$1
	kill ${pid}
}

if [ ! -f ${POOL_PATH} ]; then
	echo "Creating pool for pmemkv with pmempool tool"
	pmempool create -s ${POOL_SIZE} -l pmemkv obj ${POOL_PATH}
fi

echo "Run server with pmemkv concurrent hash map as storage ${POOL_PATH}"
run_server ${POOL_PATH}

echo "Put data into database"
curl -s -H "Content-type: application/json" -X PUT http://localhost:8000/db -d '{"message": "Hello Data"}'
echo "Read back data:"
assert "$(curl -s http://localhost:8000/db/message)" "\"Hello Data\""
echo "Shutdown server"
shutdown_server ${pid}
echo "Rerun server"
pid=$(run_server ${POLL_PATH})
echo "Read data written in previous session:"
assert "$(curl -s http://localhost:8000/db/message)" "\"Hello Data\""
echo "Remove data"
$(curl -s -X DELETE http://localhost:8000/db/message)
echo "Data was removed:"
assert "$(curl -s http://localhost:8000/db/message)" ""
echo "Shutdown server"
shutdown_server ${pid}
