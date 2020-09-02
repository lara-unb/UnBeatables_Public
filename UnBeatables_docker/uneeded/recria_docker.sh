#!/bin/bash

_RUNNING="$(docker ps --quiet --filter 'ancestor=unbeatables/workshop')"
if [ ! -z "${_RUNNING}" ]; then
    docker stop ${_RUNNING}
fi

_CREATED="$(docker ps --all --quiet --filter 'ancestor=unbeatables/workshop')"
if [ ! -z "${_CREATED}" ]; then
    docker rm ${_CREATED}
fi

docker rmi -f $(docker images -q --filter=dangling=true)

docker rmi unbeatables/workshop

docker build -t unbeatables/workshop -f Dockerfile-workshop .

exit 0
