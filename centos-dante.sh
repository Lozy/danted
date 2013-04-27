#!/bin/sh
#For Centos

serverip=$(grep $(hostname) /etc/hosts| awk '{print $1}')
if [[ "$serverip" == "127.0.0.1" ]] || [[ "$serverip" == "" ]] ;then
	serverip=`ifconfig venet0:0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
fi

echo "Auto Generate Your Ip address".$serverip

read -p "Corret it? Or press Enter" newip
read -p "Sock 5 Port: (Default 9200)" newport

if [ "$newip" -ne "" ];then serverip=newip
fi

if [ "$newport" -eq "" ];then newport=9200
fi

yum update -y
yum install gcc make -y

wget ftp://ftp.inet.no/pub/socks/dante-1.3.2.tar.gz
tar zxvf dante*
cd dante*
./configure
make && make install

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

cat >> ~/dante<<EOF
#!/bin/bash

killall danted
killall sockd
rm -rf /var/log/danted.log

sleep 2
/usr/local/sbin/sockd -f /etc/danted.conf &

exit 0
EOF

/usr/local/sbin/sockd -f /etc/danted.conf &
rm dante-1.3.2* -rf
rm centos-dante.sh -rf
exit

