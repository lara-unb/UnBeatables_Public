#!/bin/bash
################################################################################
#      Prepara imagens de containers para uso nos workshops da Unbeatables     #     
################################################################################
# Conteúdo: Instala no Host os softwares noVNC e Docker
#           Cria servidor web com Nginx
#           Cria imagem base com interface gráfica e servidor VNC
#           Cria imagem com Choregraphe Suite
################################################################################
# Para instalação do Choregraphe, copie o arquivo de instalação para o diretório
# "workshop-config"
################################################################################
# 01/06/2019 Lívia Fonseca <liviagcf@gmail.com> - Implementação inicial
################################################################################

### Funções

# ============================================================================ #
# Restaura ambiente
# ============================================================================ #
clean() {
    echo -ne "\e[?25h"  # reapresenta cursor
    unset "${!INST_@}"  # exclui variáveis de ambiente definidas pelo script
}

# ============================================================================ #
# Restaura ambiente e informa cancelamento do script pelo usuário
# ============================================================================ #
abort() {
    [[ $INST_SPT_LVL == $SHLVL ]] && echo -e "\n\e[1;31mExecução cancelada pelo usuário\e[m"
    clean
    exit 1
}

# ============================================================================ #
# Mensagem inicial do script
# ============================================================================ #
title() {
    echo 
    echo -e "\e[f\e[J\e[1;36m======================================================="
    echo -e "Instalação do ambiente para treinamentos da UnBeatables"
    echo -e "=======================================================\e[m"
    date
    echo 
}

# ============================================================================ #
# Mensagens diversas
# ============================================================================ #
msg_warn() {
    echo -e "\e[1;33mAVISO:\e[m $@"
}

msg_error() {
    echo -e "\a\e[1;31mERRO:\e[m $@"
}
# ============================================================================ #
# Aguarda finalização dos subprocessos
# ============================================================================ #
slower() {
    sleep 30
    _slow=1
}

spin() {
    _spin_ch='-\|/'
    i=0
    while [ 1 ]; do
        i=$(( (i+1) %4 ))
	local text=$@
	[[ $_slow > 0 ]] && text="$text Pode demorar um pouco..."
        echo -en "\r$text ${_spin_ch:$i:1}" 
        sleep .1
    done
}

proc_wait() {
    _excode=0
    _execid=$1
    _longer=0
    shift
    echo -e $@ >> $INST_LOGFILE
    echo -ne "\e[?25l"  # esconde cursor
    slower &
    _slowid="$!"
    spin $@ &
    _spinid="$!"   
    wait $_execid
    _excode=$?
    kill $_spinid 2> /dev/null
    wait $_spinid 2> /dev/null
    kill $_slowid 2> /dev/null
    wait $_slowid 2> /dev/null
    echo -ne "\e[?25h"  # reapresenta cursor
    if [ "$_excode" == "0" ]; then
        echo -e "\r\e[K$@ [\e[1;32mOK\e[m]"
    else
        echo -e "\r\e[K$@ [\e[1;31mERRO\e[m]"
    fi
}

# ============================================================================ #
# verifica permissões para execução do script
# ============================================================================ #
check_sudo_perm() {
    [ "$(id -u)" == "0" ] && return
    ([[ -f "$INST_WWW_DIR/noVNC/index.html" ]] && systemctl is-active --quiet docker) && return
    USER_GROUPS=$(groups)
    if [[ ! " $USER_GROUPS " =~ " sudo " ]]; then
        msg_error "Você não tem as permissões necessárias para execução deste script: group 'sudo'."
        exit 1
    fi
    msg_warn "Serão necessários privilégios de superusuário para execução deste script."
    [[ $(sudo echo 0) ]] || exit 1
}

check_docker_perm() {
    [ "$(id -u)" == "0" ] && return
    USER_GROUPS=$(groups)
    if [[ ! " $USER_GROUPS " =~ " docker " ]]; then
        GROUP_USERS=$(cat /etc/group | egrep "^docker" | cut -d ':' -f4)
        if [[ " $GROUP_USERS " =~ " $USER " ]]; then
            newgrp docker <<-EOD
		cd $_DIR
		exec $0 cont
		EOD
            exit 0
        else
            msg_error "Você não tem as permissões necessárias para execução deste script: group 'docker'."
            exit 1
        fi
    fi
}

# ============================================================================ #
# copia arquivos necessários para continuar instalação
# ============================================================================ #
check_choregraphe() {
    local CHOREGRAPHE_INSTALLER=( $(ls choregraphe-suite-*.tar.gz 2> /dev/null) )
    if [ -z "$CHOREGRAPHE_INSTALLER" ]; then
        msg_warn "Instalador do Choregraphe não localizado. Imagem \e[1;34m${_DOCKER_WORK}\e[m não será gerada."
	read -p "Continua (S/n)? " -i "S" -N 1 resp
	echo
	if [[ "${resp}" == @(N|n) ]]; then
            echo -e "\e[1;33mAcesse o site da SoftBank Robotics: \e[0;34mhttps://community.ald.softbankrobotics.com/en/resources/software\e[1;33m\n"\
                    "e baixe o '\e[m.tar.gz\e[1;33m' do Choregraphe no diretório '\e[m$_DIR\e[1;33m'.\e[m"
            echo "Instalação interrompida."
            exit 0
        fi
        unset INST_CGRAPHE
        return 0
    fi
    if [[ ${#CHOREGRAPHE_INSTALLER[@]} == 1 ]]; then
        export INST_CGRAPHE="${CHOREGRAPHE_INSTALLER[0]}"
    else
        local _try=0
        msg_warn "Mais de uma versão do Choregraphe foi encontrada."
	PS3="Informe qual será instalada:"
        select installer in "${CHOREGRAPHE_INSTALLER[@]}" "Sair"; do
            if [[ $REPLY -le ${#CHOREGRAPHE_INSTALLER[@]} ]]; then
                export INST_CGRAPHE="$installer"
                break;
            elif [[ $REPLY -eq $(( ${#CHOREGRAPHE_INSTALLER[@]} + 1)) ]]; then
                abort
            else
                msg_error "Opção '$REPLY' não é válida !!"
                [[ $((++_try)) -gt 5 ]] && abort  # Aceita um máximo de 5 tentativas
                echo -en "\e[2A\e[D\e[K"           # Reposiciona o cursor na linha do prompt
            fi
        done
    fi
}

# ============================================================================ #
# apaga imagens caso existam
# ============================================================================ #
image_exists() {
	[[ -z "$(which docker)" ]] && return
	if  docker images --format="{{.Repository}}" | egrep "^$_DOCKER_BASE" &> /dev/null; then
		msg_warn "A imagem \e[1;35m${_DOCKER_BASE}\e[m ou suas derivadas já existem e serão excluídas."
		read -p "Continua (S/n)? " -i "S" -N 1 resp
		echo
		if [[ "${resp}" == @(N|n) ]]; then
			echo "Finalizando script."
			exit 0
		fi
	fi
}	

# ============================================================================ #
# verifica se há containers das imagens a serem sobrescritas e encerra-os
# ============================================================================ #
container_running() {
	[[ -z "$(which docker)" ]] && return
	_RUNNING=$(docker ps --format="{{.ID}}\t{{.Image}}" | egrep "$_DOCKER_BASE" | cut -f1)
	if  [[ -n "${_RUNNING}" ]]; then
		msg_warn "Há containers da imagem \e[1;35m${_DOCKER_BASE}\e[m ou derivadas em execução."
		read -p "Cancela (S/n)? " -i "S" -N 1 resp
		echo 
		if [[ "${resp}" == @(N|n) ]]; then
			echo "Finalizando script."
			exit 0
		fi
		unset resp
		docker stop ${_RUNNING} &>> $INST_LOGFILE &
		pid=$!
		proc_wait $pid "Encerrando containers em execução..."
	fi
}	

# ============================================================================ #
# atualiza Dockerfile com as informacoes deste build
# ============================================================================ #
update_dockerfile() {
    local buildDate=$(date +%Y-%m-%d)

    find . -type f -name 'Dockerfile*' | while read file ; do
	sed -i -e "/^\(FROM[[:space:]]\+ubuntu\):.*/,\${s//\1:${release}/;b};\$q1" $file \
        && echo -e "atualiza release do ubuntu para '$release' em $file" >> $INST_LOGFILE
	sed -i -e "/^\(ENV[[:space:]]\+BUILD_DATE\) .*/,\${s//\1 $buildDate/;b};\$q1" $file \
        && echo -e "atualiza BUILD_DATE para '$buildDate' em $file" >> $INST_LOGFILE
    done
}

# ============================================================================ #
# instala e configura noVNC (HTML5 base VNC viewer)
# ============================================================================ #
install_noVNC() {
    [ -d "$INST_WWW_DIR/noVNC" ] || mkdir -vp $INST_WWW_DIR/noVNC &>> $INST_LOGFILE
    wget -qO- https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz | tar xz --strip 1 -C $INST_WWW_DIR/noVNC &>> $INST_LOGFILE
    chmod +x -v $INST_WWW_DIR/noVNC/utils/*.sh &>> $INST_LOGFILE
    cp -v $INST_SRC_DIR/*.html $INST_WWW_DIR/noVNC &>> $INST_LOGFILE
    cp -v $INST_SRC_DIR/pt.json $INST_WWW_DIR/noVNC/app/locale &>> $INST_LOGFILE
    [ -d "/var/log/nginx" ] || mkdir -vp /var/log/nginx &>> $INST_LOGFILE
}

# ============================================================================ #
# instala container manager Docker
# ============================================================================ #
install_docker() {
    if [ -n "$(apt-cache search docker.io --names-only)" ]; then
	apt-get ${INST_APT_OPT} install docker.io --no-install-recommends &>> $INST_LOGFILE
    else
        apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D &>> $INST_LOGFILE
        apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' &>> $INST_LOGFILE
        apt-get ${INST_APT_OPT} update &>> $INST_LOGFILE
        apt-get ${INST_APT_OPT} install docker-engine &>> $INST_LOGFILE
    fi
    sleep 1
    if ! which docker &> /dev/null; then
        msg_error "Falha na instalação do Docker. Verifique '$(realpath $INST_LOGFILE)'."
	exit 100
    fi
    if ! systemctl enable docker.service &>> $INST_LOGFILE; then
        msg_error "Falha na instalação do Docker. Verifique '$(realpath $INST_LOGFILE)'."
	exit 1
    fi
    if ! systemctl start docker.service &>> $INST_LOGFILE; then
        msg_error "Falha na inicialização do Docker. Verifique '$(realpath $INST_LOGFILE)'."
	exit 1
    fi
    usermod -aG docker $USER &>> $INST_LOGFILE
}

# ============================================================================ #
# instala aplicativos necessários na máquina host
# ============================================================================ #
install_host() {
    echo -e "\e[1;33mInstalação dos serviços no Servidor\e[m"

# instala noVNC
    if [ -f "$INST_WWW_DIR/noVNC/index.html" ]; then
        echo -e "\e[1;32mnoVNC já instalado\e[m"
    else
        if [[ $(id -u) == 0 ]];then
            install_noVNC &
        else
            sudo --preserve-env=$INST_ENV_VNC bash -c "$(declare -f install_noVNC); install_noVNC" &
        fi
        pid=$!
        proc_wait $pid "Instalando noVNC (HTML5 based VNC viewer)..."
        if [ ! "$_excode" = "0" ]; then
            exit $_excode
        fi
    fi

# instala docker
    if systemctl is-active --quiet docker; then
        echo -e "\e[1;32mDocker já instalado e ativo\e[m"
    else
        if [[ $(id -u) == 0 ]];then
            install_docker &
        else
            sudo --preserve-env=$INST_ENV_DKR bash -c "$(declare -f install_docker); install_docker" &
        fi
        pid=$!
        proc_wait $pid "Instalando Docker..."
        if [ ! "$_excode" = "0" ]; then
            exit $_excode
        fi
    fi
}

# ============================================================================ #
# Cria todos os containers necessários para uso nos treinamentos
# ============================================================================ #
build_containers() {
# ------------------------------------------------------------------------------
    echo -e "\e[1;33mGeração das imagens dos containers\e[m"
# ------------------------------------------------------------------------------
    image_exists
    container_running
# apaga a imagens existentes no repositório Docker
    _oldimg="$(docker images --format='{{.ID}}\t{{.Repository}}' | grep $_DOCKER_BASE | cut -f1)"
    if [ ! -z "$_oldimg" ]; then
        docker rmi -f  $_oldimg &>> $INST_LOGFILE &
        pid=$!
        proc_wait $pid "Excluindo imagens pré-existentes..."
    fi
    unset _oldimg
    update_dockerfile $_DOCKER_BASE
    if [ ! -f ".dockerignore" ]; then
        echo "*" > .dockerignore
    fi
# configura rede interna dos containers
    if [ -z "$(docker network ls | grep ${_DOCKER_NETWORK})" ]; then
        docker network create ${_DOCKER_NETWORK} &>> $INST_LOGFILE &
        pid=$!
        proc_wait $pid "Configurando rede interna dos containers '\e[1;36m${_DOCKER_NETWORK}\e[m'..."
        if [ ! "$_excode" = "0" ]; then
            exit $_excode
        fi
    fi
# Gera imagem servidor WEB
    docker build -t ${_DOCKER_SERVER} -f Dockerfile-server config-server &>> $INST_LOGFILE &
    pid=$!
    proc_wait $pid "Gerando imagem do webserver '\e[1;36m${_DOCKER_SERVER}\e[m'..."
    if [ ! "$_excode" = "0" ]; then
        exit $_excode
    fi
# Gera imagem base
    docker build -t ${_DOCKER_BASE} -f Dockerfile-base config-base &>> $INST_LOGFILE &
    pid=$!
    proc_wait $pid "Gerando imagem base '\e[1;36m${_DOCKER_BASE}\e[m'..."
    if [ ! "$_excode" = "0" ]; then
        exit $_excode
    fi
# Gera imagem workshop
    [[ ! -v INST_CGRAPHE ]] && return
    ln -f $INST_CGRAPHE config-workshop/
    echo "'${INST_CGRAPHE}' será adicionado ao container '${_DOCKER_WORK}'." >> $INST_LOGFILE
    docker build -t ${_DOCKER_WORK} -f Dockerfile-workshop --build-arg CHOREGRAPHE=${INST_CGRAPHE} config-workshop &>> $INST_LOGFILE &
    pid=$!
    proc_wait $pid "Gerando imagem '\e[1;36m${_DOCKER_WORK}\e[m'..."
    if [ ! "$_excode" = "0" ]; then
        exit $_excode
    fi
}

# +++++++++++++++++++++++++++ INICIO DO PROCESSAMENTO ++++++++++++++++++++++++++
# ============================================================================ #
# Prepara o ambiente
# ============================================================================ #
_LINUX_DISTRO="$(grep DISTRIB_ID /etc/lsb-release | cut -d '=' -f2)"
_LINUX_RELEASE="$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d '=' -f2)"
_LINUX_CODENAME="$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d '=' -f2)"

if [ "$_LINUX_DISTRO" != "Ubuntu" ]; then
    msg_error "Este script deve ser executado somente no Ubuntu"
    exit 1
fi

if [ -z "${distro}" ]; then
    distro="${_LINUX_CODENAME}"
    release="${_LINUX_RELEASE}"
fi

export INST_APT_OPT="-y -q"
export INST_CGRAPHE=""
export INST_LOGFILE="./install.log"
export INST_SPT_LVL="${INST_SPT_LVL:-$SHLVL}"
export INST_SRC_DIR="./config-host"
export INST_WWW_DIR="/var/www"
export INST_ENV_VNC="INST_LOGFILE,INST_APT_OPT,INST_SRC_DIR,INST_WWW_DIR,USER"
export INST_ENV_DKR="INST_LOGFILE,INST_APT_OPT,USER"

_DIR=$(dirname $(realpath "$0"))
_DOCKER_BASE="unbeatables"
_DOCKER_WORK="$_DOCKER_BASE/workshop"
_DOCKER_SERVER="$_DOCKER_BASE/webserver"
_DOCKER_NETWORK="${_DOCKER_BASE}"

trap abort SIGABRT SIGINT SIGTERM
trap clean ERR

cd $_DIR
# ============================================================================ #
# Processa opções
# ============================================================================ #
case "$1" in
    cont)
        msg_warn "Permissões validadas. Continuando execução do script."
        build_containers
        ;;
    *)
	rm -f $INST_LOGFILE
	touch $INST_LOGFILE
        title
        check_sudo_perm
        install_host
	check_choregraphe
        check_docker_perm
        build_containers
	;;
esac
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
clean
echo ""
echo -e "\e[1;32mInstalação finalizada com sucesso\e[m"
date
echo ""
echo ""
echo ""

exit 0
################################################################################
