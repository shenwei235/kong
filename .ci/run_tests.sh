#set -e

export BUSTED_ARGS="-o gtest -v --exclude-tags=ci"
export TEST_CMD="KONG_SERF_PATH=$SERF_PATH bin/busted $BUSTED_ARGS"

createuser --createdb kong
createdb -U kong kong_tests

if [ "$TEST_SUITE" == "lint" ]; then
    make lint
elif [ "$TEST_SUITE" == "unit" ]; then
    make test
elif [ "$TEST_SUITE" == "integration" ]; then
    export KONG_SERF_PATH=$SERF_PATH
    bin/busted spec/02-integration/03-admin_api/09-targets_routes_spec.lua -o=gtest -v --tags=o
    cat servroot/logs/error.log
elif [ "$TEST_SUITE" == "plugins" ]; then
    make test-plugins
fi
