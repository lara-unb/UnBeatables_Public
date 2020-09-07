#!/bin/bash
### interrompe o script caso algum passo retorne != 0
set -e

SHOW_LOG=false

help () {
echo  "
SINTAXE:
docker run --detach --rm --network=unbeatables unbeatables/workshop <opcoes>

OPÇÕES:
	-b, --heartbeat websockify heartbeat interval
	-d, --debug     habilita modo debug que mostra mais detalhes da ativação
        	        ex.: 'docker run unbeatables/workshop --debug bash'
	-h, --help      mostra este menu
	-l, --log       mostra o log de ativação
	-s, --skip      não inicia serviços e executa o comando informado
	                ex.: docker run unbeatables/workshop --skip bash
	-w, --wait      (default) mantém a interface gráfica e o servidor VNC rodando até receber SIGINT ou SIGTERM
"
#-w, --web       habilita acesso http ao servidor VNC
}

# Reenvia o sinal de fim de execução
terminate() {
    kill -s SIGTERM $!
    exit 0
}

if [[ $1 =~ -h|--help ]]; then
    help
    exit 0
fi

source $HOME/.bashrc

# Inibe execução do servidor VNC
if [[ $1 =~ -s|--skip ]]; then
    echo -e "Servidor VNC não será executado."
    echo -e "Executando comando: '${@:2}'"
    exec "${@:2}"
    shift
fi


if [[ $1 =~ -d|--debug ]]; then
    echo -e "Habilitando DEBUG"
    export DEBUG=true
    shift
fi

if [[ $1 =~ -b|--heartbeat ]]; then
    shift
    echo -e "Heartbeat definido para $1s"
    export WS_HEARTBEAT="$1"
    shift
fi

if [[ $1 =~ -l|--log ]]; then
    shift
    echo -e "Mostra logs de ativação"
    SHOW_LOG=true
fi

trap terminate SIGINT SIGTERM

## define local dos LOGs
LOG_DIR="$INIT_DIR"

## inicia serviços adicionais se existirem
## interessante no caso de imagens derivadas
if [ -d $INIT_DIR/startup.d ]; then
  for service in $INIT_DIR/startup.d/*.sh; do
    if [ -r $service ]; then
	if [[ $(stat -c "%a" $service) -gt 4000 ]]; then
            exec-suid $service
        else
            exec $service
        fi
    fi
  done
  unset service
fi

## resolve ip deste container
VNC_IP=$(hostname -i)

if [ -n "$DISPLAY" ]; then
    VNC_DISP="$DISPLAY"
fi

## define/troca password
echo -e "Cadastrando nova senha de acesso ao VNC"
mkdir -p "$HOME/.vnc"
VNC_PASSWD_PATH="$HOME/.vnc/passwd"

if [[ -f $VNC_PASSWD_PATH ]]; then
    echo -e "Excluindo senha de acesso já existente"
    rm -f $VNC_PASSWD_PATH
fi

if [[ $VNC_VIEW_ONLY == "true" ]]; then
    echo "Permite execução somente em modo 'VIEW ONLY'"
    #gera senha aleatória para evitar acesso
    echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20) | vncpasswd -f > $PASSWD_PATH
else
    echo "$VNC_PASSWD" | vncpasswd -f > $VNC_PASSWD_PATH
    if [[ $VNC_VIEW_ONLY == "optional" ]]; then
        echo "Permite execução em modo 'NORMAL' e 'VIEW ONLY'"
    else
        echo "Permite execução somente em modo 'NORMAL'"
    fi
fi
if [ -n "$VNC_PASSWD_VO" ]; then
    echo "$VNC_PASSWD_VO" | vncpasswd -f >> $VNC_PASSWD_PATH
else
    echo "$VNC_PASSWD" | vncpasswd -f >> $VNC_PASSWD_PATH
fi

chmod 600 $VNC_PASSWD_PATH

# ------------------------------------------------------------------------------
echo -e "Iniciando websockify (Websockets Proxy)"

WS_PARM_DBG=""
WS_PARM_LOG=""
WS_PARM_HB=""
WS_OPTIONS="$(websockify --help)"
[ -z "$(echo ${WS_OPTIONS} | egrep '[-]{2}log-file')"  ] || WS_PARM_LOG="--log-file=${LOG_DIR}/websocket.log"
[ -z "$(echo ${WS_OPTIONS} | egrep '[-]{2}heartbeat')" ] || WS_PARM_HB="--heartbeat=${WS_HEARTBEAT}"

if [[ $DEBUG == true ]]; then 
    WS_PARM_DBG="--verbose"
    echo "websockify $WS_PARM_LOG $WS_PARM_HB $WS_PORT localhost:$VNC_PORT" &> $LOG_DIR/startup.log
fi
websockify $WS_PARM_LOG $WS_PARM_HB $WS_PARM_DBG $WS_PORT localhost:$VNC_PORT &> $LOG_DIR/startup.log &
PID_SUB="$!"
sleep 1
if ! ps -p ${PID_SUB} >/dev/null; then
    PID_SUB=
    echo "Falha na ativação do websockify"
    exit 1
fi

# ------------------------------------------------------------------------------
echo -e "Excluindo locks antigos do VNC para tornar o container reconectável"
vncserver -kill $VNC_DISP || rm -rfv /tmp/.X*-lock /tmp/.X11-unix || echo "vncserver não estava em execução"

echo -e "Iniciando servidor VNC"
VNC_DEBUG=""
if [[ $DEBUG == true ]]; then 
    VNC_DEBUG="-verbose"
    echo "vncserver $VNC_DISP -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION" &> $LOG_DIR/startup.log
fi
vncserver $VNC_DISP -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION $VNC_DEBUG &> $LOG_DIR/startup.log

echo -e "Estação de trabalho em execução"
echo -e "Conecte com VNC viewer: \e[1;33m$VNC_IP:$VNC_PORT\e[m"
echo -e "Conecte com seu browser: \e[1;34mhttp://<host>/?host=$VNC_IP&port=$WS_PORT&path=websockify\e[m"

if [[ $DEBUG == true ]] || [[ $SHOW_LOG == true ]]; then
    echo -e "\n$HOME/.vnc/*$DISPLAY.log"
    tail -f $LOG_DIR/*.log $HOME/.vnc/*$DISPLAY.log
fi

if [ -z "$1" ] || [[ $1 =~ -w|--wait ]]; then
    wait $PID_SUB
else
    # comando desconhecido, executa
    echo "Executando comando: '$@'"
    exec "$@"
fi
