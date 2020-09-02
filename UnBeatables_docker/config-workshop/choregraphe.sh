#!/bin/bash
set -e

echo "Instalando Choregraphe Suite..."

# Instala pacotes da biblioteca que o Choregraphe usa
apt-get -y -q install avahi-daemon avahi-discover avahi-utils libnss-mdns libqt5gui5 libqt5x11extras5  

# Instala Choregraphe Suite no diretório padrão
CS_DIR="/opt/SoftbankRobotics/ChoregrapheSuite"
CS_ARQ="$(ls -d ${INSTALL_SCRIPTS}/choregraphe-suite-*)"
if [ ! -d "${CS_ARQ}" ]; then
	echo "Choregraphe Suite não instalado"
	exit 100
fi
[ -d "${CS_DIR}" ] || mkdir -p ${CS_DIR}
mv -f -t ${CS_DIR} ${CS_ARQ}/* && rmdir ${CS_ARQ}

# Corrige versao zlib (incompatibilidade entre a empacotada no software e a instalada na distro atual)
if [ -h "${CS_DIR}/lib/libz.so" ] || [ -h "${CS_DIR}/lib/libz.so.1" ]; then
	LIBZ="$(whereis libz.so.1 | cut -d ":" -f 2)"
	if [ -n "$LIBZ" ] && [[ "$(basename $(readlink -f ${CS_DIR}/lib/lib.so.1))" != "$(basename $(readlink -f ${LIBZ}))" ]]; then
	    	ln -vfs $LIBZ "${CS_DIR}/lib/libz.so"
	    	ln -vfs $LIBZ "${CS_DIR}/lib/libz.so.1"
	fi
fi
update-rc.d avahi-daemon enable
