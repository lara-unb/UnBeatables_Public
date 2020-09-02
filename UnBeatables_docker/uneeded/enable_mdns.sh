#!/bin/bash

echo "Habilitando mDNS"
apt-get -y -q update && apt-get -y -q install avahi-daemon avahi-utils avahi-discover libnss-mdns
find /etc/avahi -type f -name 'avahi-daemon.conf' | while read file ; do \
    sed -i -e "s/^[#]\?\(domain-name=\).*/\1local/" $file;
    sed -i -e "s/^[#]\?\(publish-hinfo=\).*/\1yes/" $file;
    sed -i -e "s/^[#]\?\(publish-workstation=\).*/\1yes/" $file;
    sed -i -e "s/^rlimit-/#rlimit-/" $file;
done
update-rc.d avahi-daemon enable
