#!/bin/sh
#For Debian

serverip=$(grep $(hostname) /etc/hosts| awk '{print $1}')

if [ "$serverip" -eq "127.0.0.1" ] || [ "$serverip" -eq "" ] ;then
  serverip=$(ifconfig venet0:0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " ")
fi

echo "Auto Generate Your Ip address".$serverip
read -p "Corret it? Or press Enter" newip
read -p "Sock 5 Port[1024-65535]: (Default 9200)" newport

if [ "$newip" -ne "" ];then serverip=newip
fi

if [ "$newport" -eq "" ];then newport=9200
fi


apt-get update
apt-get install nano dante-server -y

cat >/etc/danted.conf<<EOF
internal: $serverip  port = $newport
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

/etc/init.d/danted start
rm debian-dante.sh -f
cat >>/var/spool/cron/root<<EOF
0 0 * * * killall danted;rm -rf /var/log/daned.log;/etc/init.d/danted start > /dev/null 2>&1
EOF
crontab -u root /var/spool/cron/root
exit
