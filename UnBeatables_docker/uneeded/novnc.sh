#!/bin/bash

. params.sh

_LOGFILE="/install.log"

export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
_excode=0

# ====================== Aguarda finalização do processo =======================
proc_wait() {
    spin='-\|/'

    i=0
    while kill -0 $1 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r$2 ${spin:$i:1}"
      sleep .1
    done
    _excode=$?

    if [ $_excode -eq 0 ]; then
	printf "\r                           \r"
    else
	printf "\rERROR.                     \n"
	exit 1
    fi
}
# ==============================================================================

# ====================== instalacao do choregraphe =============================
echo "Instalando noVNC..."
wget -q https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz &
pid=$!
proc_wait $pid "por favor, aguarde..."
tar xzf v1.0.0.tar.gz &
pid=$!
proc_wait $pid "por favor, aguarde..."
rm v1.0.0.tar.gz
# ==============================================================================
