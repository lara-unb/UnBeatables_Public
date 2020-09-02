#!/bin/bash

set -e
set -u

echo "Instalando servidor VNC"
apt-get update
if [ -n "$(apt-cache search tigervnc-standalone-server --names-only)" ]; then
    apt-get -y -q install tigervnc-common tigervnc-standalone-server --no-install-recommends
elif [ -n "$(apt-cache search tightvncserver --names-only)" ]; then
    apt-get -y -q install tightvncserver --no-install-recommends
else
    echo "ERRO: Não foi encontrado nenhum servidor VNC adequado nesta distribuição"
    exit 100
fi
apt-get -y -q install websockify --no-install-recommends 
apt-get -y -q clean

if ! which vncserver > /dev/null; then
    echo "Falha na instalação do servidor VNC"
    exit 1
fi

if ! which websockify > /dev/null; then
    echo "Falha na instalação do proxy websocket"
    exit 1
fi
