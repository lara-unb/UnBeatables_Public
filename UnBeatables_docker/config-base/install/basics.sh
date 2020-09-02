#!/bin/bash

set -e

echo "Instalando pacotes básicos"

mkdir -p $HOME

apt-get -y -q update
apt-get -y -q install dbus ifupdown isc-dhcp-client man-db nano netbase net-tools openssl udev wget --no-install-recommends
apt-get -y -q clean
cp -r /etc/skel/. $HOME

