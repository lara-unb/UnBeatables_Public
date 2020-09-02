#!/bin/bash

# Ultima atualizacao: 07/04/2019
# ==============================================================================
echo 
echo -e "\e[1;36m======================================================="
echo -e "Instalação do ambiente para treinamentos da UnBeatables"
echo -e "=======================================================\e[m"
date
echo 

if [ "$(id -u)" != "0" ]; then
   echo -e "\e[1;37mERRO:\e[m Este script deve ser executado como 'root'."
   exit 0
fi

if ! which debootstrap > /dev/null 2>&1; then
   echo -e "\e[1;37mERRO:\e[m Utilitário 'debootstrap' não instalado."
   exit 1
fi

if ! which chroot > /dev/null 2>&1; then
   echo -e "\e[1;37mERRO:\e[m Utilitário 'chroot' não instalado."
   exit 1
fi

_APT="-y -q"
_ARCH="amd64"
_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
_DOCKER_BASE="unbeatables"
_DOCKER_WORK="$_DOCKER_BASE/workshop"
_LOGFILE="./install.log"
_SOURCE_DIR='./server-source'
_WS_HTML_DIR='/var/www'
_LINUX_DISTRO="$(cat /etc/lsb-release | grep DISTRIB_ID | cut -d '=' -f2)"
_LINUX_RELEASE="$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d '=' -f2)"
_LINUX_CODENAME="$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d '=' -f2)"


cd $_DIR
# ==============================================================================


# ============ Obtém parâmetros e valida os obrigatórios =======================
. params.sh

if [ "$_LINUX_DISTRO" != "Ubuntu" ]; then
    echo -e "\e[1;31mERRO:\e[m Este script deve ser executado somente no ${_LINUX_DISTRO}"
    exit 1
fi

if [ -z "${distro}" ]; then
    distro="${_LINUX_CODENAME}"
fi

if [ -z "${repo}" ]; then
    repo="http://archive.ubuntu.com/ubuntu"
fi
# ==============================================================================

# ====================== Aguarda finalização do processo =======================
spin() {
    _spinch='-\|/'

    i=0
    while [ 1 ]; do
        i=$(( (i+1) %4 ))
        echo -en "\r$@ ${_spinch:$i:1}" 
        sleep .1
    done
}

proc_wait() {
    _excode=0
    _execid=$1
    shift
    echo -e $@ >> $_LOGFILE
    spin $@ &
    _spinid="$!"
    wait $_execid
    _excode=$?
    kill $_spinid 2> /dev/null
    wait $_spinid 2> /dev/null

    if [ "$_excode" == "0" ]; then
        echo -e "\r$@ [\e[1;32mOK\e[m]"
    else
        echo -e "\r$@ [\e[1;31mERRO\e[m]"
    fi
}
# ==============================================================================

# =========================== prepara pasta destino ============================
dest_folder() {
    odir="${_DOCKER_BASE}Img"
    if [ -z "${odir}" ]; then
        echo -e "\e[1;37mERRO CRÍTICO.\e[m"
        exit 1
    fi

    if [ ! -d ${odir} ]; then
		mkdir -p ${odir} &
		pid=$!
		proc_wait $pid "Criando pasta \e[1;34m$odir\e[m..."
    else
		echo -e "\e[1;33mAVISO:\e[m A pasta \e[1;34m$odir\e[m já existe. \e[1;37mO conteúdo será apagado.\e[m"
		read -p "Continua (S/n)? " -i "S" -N 1 resp
		echo 
		if [[ "${resp}" == @(N|n) ]]; then
			exit 0
		fi
		rm -rf $odir/* >> $_LOGFILE 2>&1 &
		pid=$!
		proc_wait $pid "Apagando pasta \e[1;34m$odir\e[m..."
    fi
    sync
    sleep 1
}
# ==============================================================================

# ======================== cria 'sources.list' completo ========================
configpkg() {
cat > $odir/sources.list << _EOF_
deb $repo/ $distro main restricted universe multiverse
deb-src $repo/ $distro main restricted universe multiverse
deb $repo/ $distro-updates main restricted universe multiverse
deb-src $repo/ $distro-updates main restricted universe multiverse
deb $repo/ $distro-security main restricted universe multiverse
deb $repo/ $distro-backports main restricted universe multiverse
_EOF_
}
# ==============================================================================

# ============== copia arquivos necessários para continuar instalação ==========
prep2ndstage() {
    mkdir -vp $odir/etc/default >> $_LOGFILE 2>&1
    mkdir -vp $odir/usr/local/bin >> $_LOGFILE 2>&1
    mkdir -vp $odir/usr/bin >> $_LOGFILE 2>&1

    cp -v /etc/timezone $odir/etc >> $_LOGFILE 2>&1
    cp -v imagem.sh $odir/imagem.sh >> $_LOGFILE 2>&1
    cp -v params.sh $odir/params.sh >> $_LOGFILE 2>&1
    
    if [ -f "${CHOREGRAPHE_INSTALLER}" ]; then
        cp -v ${CHOREGRAPHE_INSTALLER} $odir/choregraphe-suite-setup >> $_LOGFILE 2>&1
        chmod -v +x $odir/choregraphe-suite-setup >> $_LOGFILE 2>&1
    fi

    mv -v $_LOGFILE $odir >> $_LOGFILE 2>&1
}
# ==============================================================================

# ============== instala e configura noVNC (HTML5 base VNC viewer) =============
install_webserver() {
    _ret=0
    if systemctl is-active --quiet nginx; then
        echo -e "Web server já instalado e ativo" >> $_LOGFILE 2>&1
    else
        apt-get ${_APT} install nginx --no-install-recommends >> $_LOGFILE 2>&1
        _ret=$?
    fi
    # remove definições do servidor padrão
    if [ -h "/etc/nginx/sites-enabled/default" ]; then 
        unlink /etc/nginx/sites-enabled/default >> $_LOGFILE 2>&1
    else
        return $_ret
    fi
}
# ==============================================================================

# ============== instala e configura noVNC (HTML5 base VNC viewer) =============
install_noVNC() {
    if [ -h "/etc/nginx/sites_available/workshop_site.conf" ]; then
        echo -e "noVNC já instalado" >> $_LOGFILE 2>&1
        return 0
    fi
    [ -d "$_WS_HTML_DIR/noVNC" ] || mkdir -p $_WS_HTML_DIR/noVNC >> $_LOGFILE 2>&1
    wget -qO- https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz | tar xz --strip 1 -C $_WS_HTML_DIR/noVNC >> $_LOGFILE 2>&1
    chmod +x -v $_WS_HTML_DIR/noVNC/utils/*.sh >> $_LOGFILE 2>&1
    cp -v $_SOURCE_DIR/*.html $_WS_HMTL_DIR/noVNC >> $_LOGFILE 2>&1
    cp -v $_SOURCE_DIR/workshop_site.conf /etc/nginx/sites-available >> $_LOGFILE 2>&1
    ln -sfv /etc/nginx/sites-available/workshop_site.conf /etc/nginx/sites-enabled/ >> $_LOGFILE 2>&1
}
# ==============================================================================

# ===== verifica se a imagem a ser gravada já existe (será apagada depois) =====
image_exists() {
    [ -n "$(which docker)" ] || return
	if  docker images --format="{{.Repository}}" | egrep "^$_DOCKER_BASE" > /dev/null 2>&1; then
		echo -e "\e[1;33mAVISO:\e[m A imagem \e[1;35m${_DOCKER_BASE}\e[m ou suas derivadas já existem e serão excluídas."
		read -p "Continua (S/n)? " -i "S" -N 1 resp
		echo 
		if [[ "${resp}" == @(N|n) ]]; then
			echo "Finalizando script."
			exit 0
		fi
	fi
}	
# ==============================================================================

# == verifica se há containers das imagens a serem sobrescritas e encerra-os ===
container_running() {
    [ -n "$(which docker)" ] || return
	if  docker ps --format "{{.Image}}" | egrep "$_DOCKER_BASE" > /dev/null; then
		echo -e "\e[1;33mAVISO:\e[m Há containers da imagem \e[1;35m$_DOCKER_BASE\e[m ou derivadas em execução."
		read -p "Cancela (S/n)? " -i "S" -N 1 resp
		echo 
		if [[ "${resp}" == @(N|n) ]]; then
			echo "Finalizando script."
			exit 0
		fi
		unset resp
		docker stop $(docker ps --quiet --filter "ancestor=$_DOCKER_BASE") >> $_LOGFILE 2>&1 &
		pid=$!
		proc_wait $pid "Encerrando containers em execução..."
	fi
}	
# ==============================================================================

# ===================== instala container manager Docker =======================
install_docker() {
    if systemctl is-active --quiet docker; then
        echo -e "Docker daemon já instalado e ativo" >> $_LOGFILE 2>&1
        return 0
    fi
    if [ -n "$(apt-cache search docker.io --names-only)" ]; then
	apt-get ${_APT} install docker.io --no-install-recommends >> $_LOGFILE 2>&1
    else
        apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >> $_LOGFILE 2>&1
        apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' >> $_LOGFILE 2>&1
        apt-get ${_APT} update >> $_LOGFILE 2>&1
        apt-get ${_APT} install -y docker-engine >> $_LOGFILE 2>&1
    fi
}
# ==============================================================================

# ============== atualiza Dockerfile com as informacoes deste build ============
update_dockerfile() {
    parent_image=$1
    refreshDate=$(date +%Y-%m-%d)

    find . -type f -name 'Dockerfile*' | while read file ; do \
        sed -i -e "s/^FROM .*/FROM $parent_image/" $file  \
        && echo -e "atualiza FROM com '$parent_image' em $file" >> $_LOGFILE;
        sed -i -e "s/^ENV REFRESHED_AT.*/ENV REFRESHED_AT $refreshDate/" $file  \
        && echo -e "atualiza ENV REFRESHED_AT com '$refreshDate' em $file" >> $_LOGFILE ;
    done
    unset parent_image
}
# ==============================================================================

# +++++++++++++++++++++++++++ INICIO DO PROCESSAMENTO ++++++++++++++++++++++++++
rm -f $_LOGFILE
touch $_LOGFILE

image_exists
container_running
dest_folder
# ==============================================================================
echo -e "\e[1;33mIniciando instalação dos serviços no Servidor\e[m"
# ============================ instala docker ==================================
install_docker &
pid=$!
proc_wait $pid "Instalando Docker Engine..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
# ==============================================================================

# ========================== instala http server ===============================
install_webserver &
pid=$!
proc_wait $pid "Instalando Web Server..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
# ==============================================================================

# ============================== instala noVNC =================================
install_noVNC &
pid=$!
proc_wait $pid "Instalando noVNC (HTML5 based VNC viewer)..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
# ==============================================================================


echo -e "\e[1;33mIniciando criação da imagem das workstations\e[m"

# ======================= instala arquivos distribuicao ========================
touch $odir/_$distro
debootstrap --arch ${_ARCH} --foreign --verbose --variant=minbase --include=apt-utils ${distro} $odir $repo >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Instalando pacotes básicos da distribuição..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
# ==============================================================================

configpkg &
pid=$!
proc_wait $pid "Atualizando 'sources.list' em \e[1;34m${odir}\e[m"
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi

prep2ndstage &
pid=$!
proc_wait $pid "Copiando arquivos auxiliares para instalação na imagem..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi

# ====================== executa debootstrap second-stage ======================
#echo -e "\e[1;33mAtivando instalação na imagem...\e[m"
if  ! chroot $odir /bin/bash /imagem.sh; then
    mv $odir/install.log $_LOGFILE > /dev/null 2>&1
    echo -e "\e[1;37mERRO:\e[m Falha na ativação da instalação interna."
    exit 1
fi

if [ ! -f $odir/_OK_ ]; then
    mv $odir/install.log $_LOGFILE > /dev/null 2>&1
    echo -e "\e[1;37mERRO:\e[m Instalação não foi concluída com êxito."
    exit 1
fi
# ==============================================================================

# ========================== limpa instalação ==================================
mv $odir/install.log $_LOGFILE > /dev/null 2>&1

rm $odir/_OK_ >> $_LOGFILE 2>&1
rm $odir/imagem.sh >> $_LOGFILE 2>&1
rm $odir/params.sh >> $_LOGFILE 2>&1
rm $odir/choregraphe-suite-setup >> $_LOGFILE 2>&1

rm -rf $odir/dev/* >> $_LOGFILE 2>&1
rm -rf $odir/proc/* >> $_LOGFILE 2>&1
rm -rf $odir/run/* >> $_LOGFILE 2>&1
rm -rf $odir/sys/* >> $_LOGFILE 2>&1
rm -rf $odir/tmp/* >> $_LOGFILE 2>&1

sync
# ==============================================================================

# ==============================================================================
# --------------- apaga a imagem existente no repositório Docker ---------------
_oldimg="$(docker images --format='{{.ID}}\t{{.Repository}}' | grep $_DOCKER_BASE | cut -f1)"
if [ ! -z "$_oldimg" ]; then
    docker rmi -f  $_oldimg >> $_LOGFILE 2>&1 &
    pid=$!
    proc_wait $pid "Excluindo imagens pré-existentes..."
fi
unset _oldimg
# ==============================================================================

# ======================== gera Docker base-image ==============================
tar -c --transform "s/^${odir}//g" $odir 2> $_LOGFILE | docker import - ${_DOCKER_BASE} >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Gerando Docker base-image '\e[1;36m${_DOCKER_BASE}\e[m'..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
cd - >> $_LOGFILE 2>&1
# ==============================================================================

# ========================== gera imagem Docker ================================
if [ ! -f .dockerignore ]; then
    echo -e "*\n!docker-source" > .dockerignore
fi
update_dockerfile $_DOCKER_BASE
docker build -t ${_DOCKER_WORK} . >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Gerando Docker image '\e[1;36m${_DOCKER_WORK}\e[m'..."
if [ ! "$_excode" = "0" ]; then
    exit $_excode
fi
# ==============================================================================

echo ""
echo -e "\e[1;32mInstalação finalizada com sucesso\e[m"
date
echo ""
echo ""
echo ""

exit 0
