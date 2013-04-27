#!/bin/sh
#For Debian

apt-get update
apt-get install nano dante-server -y

serverip=`ifconfig venet0:0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`

cat >/etc/danted.conf<<EOF
internal: $serverip  port =  2013
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
alias s5='/etc/init.d/danted start'
alias kills5='/etc/init.d/danted stop'
EOF

/etc/init.d/danted start
rm debian-dante.sh -f
cat >>/var/spool/cron/root<<EOF
0 0 * * * /etc/init.d/danted restart
EOF
crontab -u root /var/spool/cron/root
exit
