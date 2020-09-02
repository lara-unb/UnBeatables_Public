#!/bin/bash

#rm /var/log/nginx/error_default.log
#rm /var/log/nginx/access_default.log
#cp server-source/workshop_site.conf /etc/nginx/sites-available/
#nginx -s reload
_RUNNING="$(docker ps --quiet --filter 'ancestor=unbeatables/server')"
if [ ! -z "${_RUNNING}" ]; then
    docker stop ${_RUNNING}
fi

_CREATED="$(docker ps --all --quiet --filter 'ancestor=unbeatables/server')"
if [ ! -z "${_CREATED}" ]; then
    docker rm ${_CREATED}
fi

docker rmi -f $(docker images -q --filter=dangling=true)

docker rmi unbeatables/server

docker build -t unbeatables/server -f Dockerfile-server .


#touch /var/log/nginx/error_default.log
#touch /var/log/nginx/access_default.log
docker run --detach --rm --publish 80:80 --volume /var/www:/var/www --volume /var/log:/var/log --network=unbeatables --name server unbeatables/server
tail -f /var/log/nginx/error_default.log
exit 0
