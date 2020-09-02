#!/bin/bash
set -e

echo "Instalando interface gráfica (Xfce4)"
apt-get update
apt-get -y -q install dbus-x11 supervisor xfce4 xfce4-terminal xorg
apt-get -y -q remove --purge --autoremove light-locker pm-utils xscreensaver


