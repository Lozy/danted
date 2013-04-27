#!/bin/sh
#For Centos

yum update -y
yum install gcc make -y

wget ftp://ftp.inet.no/pub/socks/dante-1.3.2.tar.gz
tar zxvf dante*
cd dante*
./configure
make && make install

#serverip=`ifconfig venet0:0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
serverip=$(grep $(hostname) /etc/hosts| awk '{print $1}')

if [[ "$serverip" == "" ]];then
	serverip=`ifconfig venet0:0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
fi
cat >/etc/danted.conf<<EOF
internal: $serverip  port =  2012
external: $serverip
method: username none
logoutput: /var/log/danted.log

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0 port gt 1023
command: bind
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: connect udpassociate
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: bindreply udpreply
log: connect error
}
block {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect error
}
EOF

cat >> ~/.bashrc<<EOF
alias s5='/usr/local/sbin/sockd -f /etc/danted.conf &'
alias kills5='killall sockd'
EOF

/usr/local/sbin/sockd -f /etc/danted.conf &
rm dante-1.3.2* -rf
rm centos-dante.sh -rf
exit

