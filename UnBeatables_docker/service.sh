#!/bin/bash

CMD_STOP=""
CMD_FORCE=""
SELECT=""
if [[ $1 == "--force" ]]; then
    CMD_FORCE="1"
    shift
fi
if [[ $1 == "--stop" ]]; then
    CMD_STOP="1"
    shift
fi

SELECT="$1"

start_webserver() {
    docker run --detach --rm --publish=80:80 --volume=/var/www:/var/www --volume=/var/log:/var/log --name=webserver --network=unbeatables unbeatables/webserver
}

start() {
    docker run --detach --rm --env=VNC_PASSWD=${1:${#1}<7?0:-7} --hostname=unb$1 --name=unb$1 --network=unbeatables unbeatables/workshop 
}

stop() {
    docker stop $1
}

process() {
    RUNNING="$(docker ps -q -f=name=unb$1)"
    if [ -n "${RUNNING}" ]; then
        echo -n "Container de $2 está em execução. "
        if [ -n "${CMD_FORCE}" ]; then
            echo "Reiniciando..."
            stop ${RUNNING}
            sleep 1
        elif [ -n "${CMD_STOP}" ]; then
            echo "Desligando..."
            stop ${RUNNING}
            continue
	else
            echo "Será ignorado."
            continue
        fi
    else
	[ -n "${STOP}" ] && continue
        echo "Iniciando container de $2..."
    fi
    start $1 $2
}


WEBSERVER="$(docker ps -q -f=name=webserver)"

[ -d "/var/log/nginx" ] || mkdir -p /var/log/nginx
[ -z "$WEBSERVER" ] && start_webserver

while IFS=: read regs name; do
    [ -z "${regs}" ] && continue
    [[ "#" == "${regs:1:1}" ]] && continue 
    [ -n "${SELECT}" ] && [[ "${regs}" != "${SELECT}" ]] && continue
    process $regs $name
done < service.db
exit 0

