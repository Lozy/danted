#!/bin/bash
#
#   Dante Socks5 Server AutoInstall
#   -- Owner:       https://www.inet.no/dante
#   -- Provider:    https://sockd.info
#   -- Author:      Lozy
#

REQUEST_SERVER="https://raw.github.com/Lozy/danted/master"
SCRIPT_SERVER="https://public.sockd.info"

[ "$1" == "--no-github" ] && REQUEST_SERVER=${SCRIPT_SERVER}

if [ -s "/etc/os-release" ];then
    os_name=$(sed -n 's/PRETTY_NAME="\(.*\)"/\1/p' /etc/os-release)

    if [ -n "$(echo ${os_name} | grep -Ei 'Debian|Ubuntu' )" ];then
        printf "Current OS: %s\n" "${os_name}"
        wget -qO- --no-check-certificate ${REQUEST_SERVER}/install_debian.sh | \
            bash -s -- $@
    elif [ -n "$(echo ${os_name} | grep -Ei 'CentOS')" ];then
        printf "Current OS: %s\n" "${os_name}"
        wget -qO- --no-check-certificate ${REQUEST_SERVER}/install_centos.sh | \
            bash -s -- $@
    else
        printf "Current OS: %s is not support.\n" "${os_name}"
    fi
else
    exit 1
fi

exit 0
