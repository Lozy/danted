#!/bin/bash
#
#   Dante Socks5 Server AutoInstall
#   -- Owner:       https://www.inet.no/dante
#   -- Provider:    https://sockd.info
#   -- Author:      Lozy
#

if [ -s "/etc/os-release" ];then
    os_name=$(sed -n 's/PRETTY_NAME="\(.*\)"/\1/p' /etc/os-release)

    if [ -n "$(echo ${os_name} | grep -Ei 'Debian|Ubuntu' )" ];then
        printf "Current OS: %s\n" "${os_name}"
        wget -qO- --no-check-certificate https://raw.github.com/Lozy/danted/master/install_debian.sh | \
            bash -s -- $@
    elif [ -n "$(echo ${os_name} | grep -Ei 'CentOS')" ];then
        printf "Current OS: %s\n" "${os_name}"
        wget -qO- --no-check-certificate https://raw.github.com/Lozy/danted/master/install_centos.sh | \
            bash -s -- $@
    else:
        printf "Current OS: %s is not support.\n" "${os_name}"
    fi
else
    exit 1

exit 0
