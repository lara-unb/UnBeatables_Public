#!/usr/bin/env bash
### interrompe o script caso haja algum passo retorne != 0
set -e

echo "Instala nss-wrapper para permitir acessar containers como usuário comum"
apt-get update 
apt-get install -y libnss-wrapper gettext
apt-get clean -y

echo "adiciona 'source config_user' ao .bashrc"

echo 'source $INIT_DIR/config_user' > $HOME/.bashrc
cat /etc/skel/.bashrc >> $HOME/.bashrc
