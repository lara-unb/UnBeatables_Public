#!/bin/bash
OPTIONS=$@

SERVER="$(docker ps -q -f=name=server)"
[ -z "$SERVER" ] && docker run --detach --rm --name=server --network=unbeatables --publish=80:80 --volume=/var/www:/var/www --volume=/var/log:/var/log unbeatables/server

RUNNING="$(docker ps -q -f=name=unb.*)"
if [ ! -z "$RUNNING" ]; then
    docker stop $(docker ps -q -f=name=unb.*)
fi
docker run --detach --rm --env=VNC_PASSWD=0034077 --hostname=unb160034077 --name=unb160034077 --network=unbeatables unbeatables/workshop 
docker run --detach --rm --env=VNC_PASSWD=0034078 --hostname=unb160034078 --name=unb160034078 --network=unbeatables unbeatables/workshop $OPTIONS
docker run --detach --rm --env=VNC_PASSWD=0034079 --hostname=unb160034079 --name=unb160034079 --network=unbeatables unbeatables/workshop
exit 0

