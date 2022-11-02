#!/bin/bash

if [ ! -d ./volumes/zk_restore ]; then
    echo "This container expects to be run with an existing data dir."
    echo "May be resolved by running:"
    echo "  mkdir -p ./volumes/zk_restore/data && cp -r ./volumes/zk1/data ./volumes/zk_restore/"
    exit 1
fi

my_id=$(cat volumes/zk_restore/data/myid)
echo "Using ZK node id of: ${my_id}"
echo "This can be edited by changing the contents of 'volumes/zk_restore/data/myid'"
echo
echo "  Enter to accept"
echo -n "  <Ctrl-C> to cancel"
read

env_file=$(mktemp)
cat zk.env  | sed -e "s/{MY_ID}/${my_id}/" > "${env_file}"

has_image=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -c zk-playground:latest)
if [ "x${has_image}" = "x0" ]; then
    echo "Bulding new ZK image"
    docker build -t zk-playground:latest -f ./zk-playground/Dockerfile ./zk-playground
fi

echo "Starting ZK restore node"

docker run \
    -ti \
    -d \
    --env-file "${env_file}" \
    --expose 2181 \
    --expose 8080 \
    --hostname zk_restore \
    --rm \
    --name zk_restore \
    --volume $(pwd)/volumes/zk_restore/data:/data \
    --volume $(pwd)/volumes/zk_restore/datalog:/datalog \
    zk-playground:latest zkServer.sh start-foreground

echo "New node in place that is running the previous cluster's data."