#!/bin/bash
DEFAULT_PORT="2014"
DEFAULT_USER="sock"
DEFAULT_PAWD="sock"
VERSION="v1.4.0"

genconfig(){
  # CONFIGFILE $IP $PORT $N
  CONFIGFILE=$1
  IP=$2
  PORT=$3
  num=$4
  cat >$CONFIGFILE<<EOF
internal: ${IP} port = ${PORT}
external: ${IP}
#socksmethod: username none
#socksmethod: username
socksmethod: pam.username
user.notprivileged: sock
logoutput: /var/log/danted.${num}.log

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect disconnect
}
socks pass {
from: 0.0.0.0/0 to: 0.0.0.0/0 port gt 1023
command: bind
log: connect disconnect
}
socks pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: connect udpassociate
log: connect disconnect
}
socks pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: bindreply udpreply
log: connect error
}
socks block {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect error
}
EOF
}

path=$(cd `dirname $0`;pwd )
( [ -n "$(grep CentOS /etc/issue)" ] \
  && ( yum install gcc g++ make vim pam-devel tcp_wrappers-devel unzip httpd-tools -y ) ) \
  || ( [ -n "$(grep -E 'Debian|Ubuntu' /etc/issue)" ] \
  && ( apt-get install gcc g++ make vim libpam-dev libwrap0-dev unzip apache2-utils -y ) )\
  || exit 0

useradd sock -s /bin/false > /dev/null 2>&1
#echo sock:sock | chpasswd
mkdir -p /etc/danted/conf

Getserverip_n=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p' | wc -l)
Getserverip=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p')

serverip=$Getserverip
( [ -z "$serverip" ] || [ -z "$(echo $Getserverip | grep "$serverip" )" ] ) && echo 'Get IP address Error.Try again OR report bug.' && exit
[ $Getserverip_n -gt 1 ] && echo "$Getserverip" && read -p  "Server IP > 1, Please Input Taget Danted Server IP OR Enter to config all " serverip

if [ -z "$serverip" ];then
   i=0
   echo "$Getserverip" | while read theip;do
      port=$DEFAULT_PORT
      configfile="/etc/danted/conf/sockd-"$(echo $Getserverip | sed 's/.*\.\(.*\)/\1/g')"${i}.conf"
   	  genconfig $configfile $theip $port $i
   	  i=$((i+1))
   done
else
      port=$DEFAULT_PORT
      configfile="/etc/danted/conf/sockd-"$(echo $serverip | sed 's/.*\.\(.*\)/\1/g')"${i}.conf"
   	  genconfig $configfile $serverip $port 0
fi

mkdir -p /tmp
cd /tmp

#start-stop-daemon
if [ -z "$(command -v start-stop-daemon)" ];then
wget http://developer.axis.com/download/distribution/apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
tar zxvf apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
gcc apps/sys-utils/start-stop-daemon-IR1_9_18-2/start-stop-daemon.c -o start-stop-daemon -o /usr/local/sbin/start-stop-daemon
fi
#libpam-pwdfile
if [ ! -s /lib/security/pam_pwdfile.so ];then
wget https://github.com/tiwe-de/libpam-pwdfile/archive/master.zip -O master.zip
unzip master.zip
cd libpam-pwdfile-master/
make && make install
cd ../
fi

if [ ! -s /etc/danted/sbin/sockd ] || [ -z "$(/etc/danted/sbin/sockd -v | grep "$VERSION")" ];then
wget http://www.inet.no/dante/files/dante-1.4.0.tar.gz
tar zxvf dante*
cd dante*
./configure --with-sockd-conf=/etc/danted/conf/sockd.conf --prefix=/etc/danted
make && make install
cd ../../
fi
#Complile Done
rm /tmp/* -rf

cat > /etc/pam.d/sockd  <<EOF
auth required pam_pwdfile.so pwdfile /etc/danted/socks.passwd
account required pam_permit.so
EOF
/usr/bin/htpasswd -c -d -b /etc/danted/socks.passwd ${DEFAULT_USER} ${DEFAULT_PAWD}

cat > /etc/init.d/danted <<'EOF'
#! /bin/bash
### BEGIN INIT INFO
# Provides:          danted
# Reprogarm:         airski
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SOCKS (v4 and v5) proxy daemon (danted)
### END INIT INFO
#
# dante socks5 daemon for Debian/Centos

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/etc/danted/sbin/sockd
DESC="Dante SOCKS daemon"
CONFIGDIR=/etc/danted/conf

test -f $DAEMON || exit 0

set -e

start_daemon_all(){
    ls ${CONFIGDIR}/*.conf | while read configed;do
    	NAME=$(echo $configed | sed 's/.*\/\(.*\)\.conf/\1/g')
    	PIDFILE=/var/run/$NAME.pid
    	LOGFILE=$(cat $configed | grep '^logoutput' | sed 's/.*logoutput: \(.*\).*/\1/g')

    	echo -n "  config $NAME "
    	
    	if [ -s $PIDFILE ] && [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ];then
    	     echo -e "\033[1;31m [ Runing;Failed ] \033[0m" 
    	     continue
    	fi

        echo >$PIDFILE
        cp /dev/null $LOGFILE

        if ! egrep -cve '^ *(#|$)' \
	       -e '^(logoutput|user\.((not)?privileged|libwrap)):' $configed > /dev/null
	    then
		   echo -e "\033[1;31m [ not configured ] \033[0m"
		   continue
	    fi
        start-stop-daemon --start --quiet --background --oknodo --pidfile $PIDFILE \
		--exec $DAEMON -- -f $configed -p $PIDFILE
		( [ -s $PIDFILE ] && echo -e "\033[32m [ Runing ] \033[0m" ) || echo -e "\033[1;31m  [ Faild ] \033[0m"
    done
}
stop_daemon_all(){
    ls ${CONFIGDIR}/*.conf | while read configed;do
    	NAME=$(echo $configed | sed 's/.*\/\(.*\)\.conf/\1/g')
    	PIDFILE=/var/run/$NAME.pid
        echo -n "  config $NAME "
        if [ ! -s $PIDFILE ];then 
          echo -e "\033[1;31m  [ PID.LOST;Unable ] \033[0m" 
          continue
        fi
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE \
		--exec $DAEMON -- -f $configed -p $PIDFILE
		( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] && \
			echo -e "\033[1;31m  [ Failed ] \033[0m" ) || echo -e "\033[32m [ Stop ] \033[0m"
    done
}
reload_daemon_all(){
    ls ${CONFIGDIR}/*.conf | while read configed;do
    	NAME=$(echo $configed | sed 's/.*\/\(.*\)\.conf/\1/g')
    	PIDFILE=/var/run/$NAME.pid
        echo -n "  config $NAME "
        if [ -s $PIDFILE ];then
        	if [ -z "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ];then
        	  echo -e "\033[1;31m [ PID.DIE;Unable ] \033[0m"  
        	  continue
        	fi
       else
            echo -e "\033[1;31m [ PID.LOST;Unable ] \033[0m" 
            continue
        fi
        start-stop-daemon --stop --signal 1 --quiet --oknodo --pidfile $PIDFILE \
		--exec $DAEMON -- -f $configed -p $PIDFILE
		( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] \
			&& echo -e "\033[32m [ Runing ] \033[0m" ) || echo -e "\033[1;31m [ Failed ] \033[0m"
    done
}
status_daemon_all(){
	ls ${CONFIGDIR}/*.conf | while read configed;do
		NAME=$(echo $configed | sed 's/.*\/\(.*\)\.conf/\1/g')
    	PIDFILE=/var/run/$NAME.pid
        echo -n "  config $NAME " $(cat $configed | grep '^internal' | sed 's/internal:\(.*\)port.*=\(.*\)/\1:\2/g' | sed 's/ //g')"  "
        if [ ! -s $PIDFILE ];then
        	echo -e "\033[1;31m [ Stop ] \033[0m"
        	continue
        fi
        ( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] \
        	&& echo -e "\033[32m [ Runing ] \033[0m" ) || echo -e "\033[1;31m [ PID.DIE;Unable ] \033[0m"
    done
    echo ">>>>>>>>>>>>>>>>>>>>>>>>"
    echo "  Active User:" $(cat /etc/danted/socks.passwd | while read line;do echo $line| sed 's/\(.*\):.*/\1/';done) 
}
add_user(){
	User=$1
	Passwd=$2
	( [ -z "$User" ] || [ -z "$Passwd" ] ) && echo " Error: User or password can't be blank" && return 0 
    /usr/bin/htpasswd -d -b /etc/danted/socks.passwd ${User} ${Passwd}
}
del_uer(){
   	User=$1
	[ -z "$User" ] && echo " Error: User Name can't be blank" && return 0 
    /usr/bin/htpasswd -D /etc/danted/socks.passwd ${User}
}
case "$1" in
  start)
	echo "Starting $DESC: "
	start_daemon_all
	;;
  stop)
	echo "Stopping $DESC: "
	stop_daemon_all
	;;
  reload)
	echo "Reloading $DESC configuration files."
	reload_daemon_all
  ;;
  restart)
	echo "Restarting $DESC: "
	stop_daemon_all
	sleep 1
	start_daemon_all
	;;
  status)
    echo "Curent Status Of $DESC: "
    status_daemon_all
    ;;
  add)
    echo "Adding User For $DESC: "
    add_user "$2" "$3"
    ;;
  del)
    echo "Clearing User For $DESC: "
    del_user "$2"
    ;;
  *)
	N=/etc/init.d/danted
	echo "Usage: $N {start|stop|restart|status|add|del}" >&2
	exit 1
	;;
esac

exit 0
EOF
chmod +x /etc/init.d/danted
[ -n "$(grep CentOS /etc/issue)" ]  && chkconfig --add danted
[ -n "$(grep -E 'Debian|Ubuntu' /etc/issue)" ] && update-rc.d danted defaults
ln -s /etc/danted/sbin/sockd /usr/bin/danted
service danted restart
clear

#Color Variable
CSI=$(echo -e "\033[")
CEND="${CSI}0m"
CDGREEN="${CSI}32m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CQUESTION="$CMAGENTA"
CWARNING="$CRED"
CMSG="$CCYAN"
#Color Variable

if [ -n "$(netstat -atn | grep "$DEFAULT_PORT")" ];then
  cat <<EOF
${CCYAN}+-----------------------------------------+$CEND
${CGREEN} Dante Socks5 Install Done. $CEND
${CCYAN}+-----------------------------------------+$CEND
${CGREEN} Dante Version:       $CMAGENTA 1.4.0$CEND
${CGREEN} Socks5 Info:         $CMAGENTA$CEND
EOF
 echo "${Getserverip}" | while read theip;do
    echo "${CGREEN}                      $CMAGENTA ${theip}:${DEFAULT_PORT}$CEND"
 done
 cat <<EOF
${CGREEN} Socks5 User&Passwd:  $CMAGENTA ${DEFAULT_USER}:${DEFAULT_PAWD}$CEND
${CCYAN}+_________________________________________+$CEND
EOF
 echo -e "\033[32m Dante Server Install Successfuly! \033[0m"
else
 echo -e "\033[1;31m Dante Server Install Failed! \033[0m"
 exit 
fi

cd $path
rm -rf $0
exit
