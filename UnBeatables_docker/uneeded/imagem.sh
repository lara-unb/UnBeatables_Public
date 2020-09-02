#!/bin/bash

. params.sh

_LOGFILE="/install.log"
_APT="-y -q"

export DEBIAN_FRONTEND=noninteractive

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

# ============= Atualiza lista de pacotes e faz upgrade inicial ================
update_packages() {
    mv /sources.list /etc/apt/sources.list
    apt-get ${_APT} update >> $_LOGFILE 2>&1 && apt-get ${_APT} upgrade >> $_LOGFILE 2>&1 
    apt-get ${_APT} clean >> $_LOGFILE 2>&1
}
# ==============================================================================

# === Instala e configura avahi-daemon para expor o container (mDNS Service) ===
install_mDNS() {
    apt-get ${_APT} install avahi-daemon libnss-mdns --no-install-recommends >> $_LOGFILE 2>&1
    find /etc/avahi -type f -name 'avahi-daemon.conf' | while read file ; do \
        sed -i -e "s/^#publish-workstation/publish-workstation/" $file; 
        sed -i -e "s/publish-workstation=no/publish-workstation=yes/" $file \
        && echo "habilita parâmetro 'publish-workstation' em avahi-daemon.conf" >> $_LOGFILE;
    done
}
# ==============================================================================

install_browser() {
    apt-get ${_APT} install firefox firefox-locale-${LANGPACK} --no-install-recommends >> $_LOGFILE 2>&1
    BROWSER_HOME="$(dirname $(readlink -f $(which firefox)))"
    BROWSER_CONF="${BROWSER_HOME}/browser/defaults/profile"
    mkdir -p $BROWSER_CONF
    echo <<EOF_FF
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("app.update.lastUpdateTime.addon-background-update-timer", 1182011519);
user_pref("app.update.lastUpdateTime.background-update-timer", 1182011519);
user_pref("app.update.lastUpdateTime.blocklist-background-update-timer", 1182010203);
user_pref("app.update.lastUpdateTime.microsummary-generator-update-timer", 1222586145);
user_pref("app.update.lastUpdateTime.search-engine-update-timer", 1182010203);
EOF_FF
    > ${BROWSER_CONF}/user.js
}


# ========== Instala um servidor VNC adequado e o proxy websocket  =============
install_VNC() {
    if [ -n "$(apt-cache search tigervnc-standalone-server --names-only)" ]; then
        apt-get ${_APT} install tigervnc-common tigervnc-standalone-server --no-install-recommends >> $_LOGFILE 2>&1 
    elif [ -n "$(apt-cache search tightvncserver --names-only)" ]; then
        apt-get ${_APT} install tightvncserver --no-install-recommends >> $_LOGFILE 2>&1 
    else
        echo "ERRO: Não foi encontrado nenhum servidor VNC adequado nesta distribuição" >> $_LOGFILE
        return 100
    fi
    apt-get ${_APT} install websockify --no-install-recommends >> $_LOGFILE 2>&1 
}
# ==============================================================================

# ================ instala Softbank Robotics Choregraphe Suite =================
install_choregraphe() {
# .......... instala pacotes da biblioteca Qt que o Choregraphe usa ............
	apt-get ${_APT} install libqt5gui5 libqt5x11extras5 >> $_LOGFILE 2>&1
# .............. instala Choregraphe Suite em modo desassistido ................
	USER=root 
	CS_DIR="/opt/SoftbankRobotics/ChoregrapheSuite"
	/choregraphe-suite-setup --installer-language en --mode unattended --create-taskbar-shortcut false --create-desktop-shortcut false --run-at-end false --installdir "$CS_DIR" >> $_LOGFILE 2>&1
# ..... corrige versao zlib (incompatibilidade entre v2.8 e linux cosmic) .....
	if [ -h "${CS_DIR}/lib/libz.so" ] || [ -h "${CS_DIR}/lib/libz.so.1" ]; then
            LIBZ="$(whereis libz.so.1 | cut -d ":" -f 2)"
	    if [ -n "$LIBZ" ] && [[ "$(basename $(readlink -f ${CS_DIR}/lib/lib.so.1))" != "$(basename $(readlink -f ${LIBZ}))" ]]; then
	    	unlink "$CS_DIR/lib/libz.so"
	    	ln -s $LIBZ "$CS_DIR/lib/libz.so"
	    	unlink "$CS_DIR/lib/libz.so.1"
	    	ln -s $LIBZ "$CS_DIR/lib/libz.so.1"
	    fi
	fi
	unset USER
}
# ==============================================================================

# ==================== DEBOOTSTRAP, SECOND STAGE ===============================
if [ ! -f /debootstrap/debootstrap ]; then
    echo -e "\e[1;37mERRO:\e[m A instalação dos pacotes básicos não foi concluída."
    exit 1
fi

/debootstrap/debootstrap --second-stage >> $_LOGFILE &
pid=$! 
proc_wait $pid "Configurando pacotes básicos..."
if [ ! "$_excode" = "0" ]; then
    exit 1
fi
sleep 1
# ==============================================================================

# ================= prepara ambiente para instalação ===========================
echo ${HOSTNAME} > /etc/hostname
# ------------------- define '/bin/bash' como shell padrão --------------------
cat /etc/default/useradd | sed s/"SHELL=\/bin\/sh"/"SHELL=\/bin\/bash"/g > /tmp/useradd
mv /tmp/useradd /etc/default/useradd
# ----------- atualiza lista de pacotes e faz upgrade inicial ------------------
update_packages &
pid=$!
proc_wait $pid "Atualizando pacotes... "
# ----------- evita que serviços sejam executados automaticamente --------------
cat << EOD > /usr/sbin/policy-rc.d
#!/bin/sh
echo "rc.d operations disabled for chroot"
exit 101
EOD
chmod 0755 /usr/sbin/policy-rc.d
# ==============================================================================

# ================= instala pacotes da distribuição linux ======================
# ----------------- Instala e configura pacotes de linguagem -------------------
apt-get ${_APT} install language-pack-${LANGPACK}-base locales --no-install-recommends >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Instalando pacotes de idioma ($LANGPACK)..."
apt-get ${_APT} clean >> $_LOGFILE 2>&1

locale-gen $LANG >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Configurando idioma do sistema ($LANG)..."
apt-get ${_APT} clean >> $_LOGFILE 2>&1

update-locale LANG=$LANG LC_ALL=$LANG LANGUAGE=$LANGUAGE >> $_LOGFILE 2>&1
export LANG=${LANG} >> $_LOGFILE 2>&1
export LANGUAGE=${LANGUAGE} >> $_LOGFILE 2>&1

# ----------------- Instala pacotes importantes da distribuicao ----------------
apt-get ${_APT} install dbus ifupdown isc-dhcp-client man-db nano netbase net-tools openssl udev wget --no-install-recommends >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Instalando pacotes adicionais..."

# --------------- Instala servico para descoberta da workstation ---------------
#install_mDNS &
#pid=$!
#proc_wait $pid "Instalando serviço mDNS..."
#
# ---------------------- Instala interface gráfica Xfce ------------------------
apt-get ${_APT} install dbus-x11 supervisor xfce4 xfce4-terminal xorg xterm >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Instalando interface gráfica..."

# ---------------------- Remove protetores/bloqueadores de tela ----------------
apt-get ${_APT} remove --autoremove --purge light-locker pm-utils xscreensaver >> $_LOGFILE 2>&1 &
pid=$!
proc_wait $pid "Removendo pacotes instalados automaticamente..."
apt-get ${_APT} clean >> $_LOGFILE 2>&1

# ---------------------------- Instala navegador WEB ---------------------------
install_browser &
pid=$!
proc_wait $pid "Instalando navegador WEB..."

# ----------- Instala VNC Server e pacotes necessários para NoVNC --------------
install_VNC &
pid=$!
proc_wait $pid "Instalando VNC Server e Proxy Websocket..."

# ==============================================================================

# ===================== instalações adicionais =================================
if [ -f "/choregraphe-suite-setup" ]; then
    install_choregraphe &
    pid=$!
    proc_wait $pid "Instalando Choregraphe Suite..."
fi
# ==============================================================================

apt-get ${_APT} clean >> $_LOGFILE 2>&1
rm /usr/sbin/policy-rc.d

touch /_OK_

echo -e "\e[32mPreparação da imagem, concluída.\e[m"

exit 0
