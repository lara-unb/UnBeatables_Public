#!/bin/bash

echo "Habilitando mDNS/DNS-SD"
/etc/init.d/dbus start
/etc/init.d/avahi-daemon start
