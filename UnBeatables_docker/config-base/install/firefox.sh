#!/usr/bin/env bash
set -e

echo "Instalando Firefox"

if ! which firefox > /dev/null; then
    apt-get -y update && apt-get -y install firefox
    apt-get -y clean
fi 

if ! which firefox > /dev/null; then
    echo "Falha na instalação do firefox"
    exit 100
fi

BROWSER_HOME="$(dirname $(readlink -f $(which firefox)))"
BROWSER_CONF="${BROWSER_HOME}/browser/defaults/profile"
mkdir -p $BROWSER_CONF

echo << EOF
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("app.update.lastUpdateTime.addon-background-update-timer", 1182011519);
user_pref("app.update.lastUpdateTime.background-update-timer", 1182011519);
user_pref("app.update.lastUpdateTime.blocklist-background-update-timer", 1182010203);
user_pref("app.update.lastUpdateTime.microsummary-generator-update-timer", 1222586145);
user_pref("app.update.lastUpdateTime.search-engine-update-timer", 1182010203);
EOF
> ${BROWSER_CONF}/user.js

exit $?
