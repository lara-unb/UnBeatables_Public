#!/bin/bash

find /etc/avahi -type f -name 'avahi-daemon.conf' | while read file ; do \
    sed -i -e "s/^#publish-workstation/publish-workstation/" $file  \
    && echo "retira comentario de 'publish-workstation' em avahi-daemon.conf";
    sed -i -e "s/publish-workstation=no/publish-workstation=yes/" $file \
    && echo "altera 'publish-workstation' para 'yes'em avahi-daemon.conf ";
done

