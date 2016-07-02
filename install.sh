#!/bin/bash
service danted stop > /dev/null 2>&1
rm /etc/danted -rf 

VERSION="v1.3.2"
DEFAULT_PORT="2016"
DEFAULT_USER="danted"
DEFAULT_PAWD="danted"
MASTER_IP="ip.baidu.com"
SERVERIP=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p')
###############################################------------Menu()---------#####################################################
for _PARAMETER in $*
do
    case "${_PARAMETER}" in
      --port=*)
        PORT="${_PARAMETER#--port=}"
        [ -n "$PORT" ] && DEFAULT_PORT=${PORT}
      ;;
      --ip=*)   #split in ; ip1;ip2;
        GETSERVERIP=$( echo "${_PARAMETER#--ip=}" | sed 's/;/\n/g' | sed '/^$/d')
        [ -n "${GETSERVERIP}" ] && SERVERIP="${GETSERVERIP}"
      ;;
      --user=*)
        user="${_PARAMETER#--user=}"
        [ -n "${user}" ] && DEFAULT_USER="${user}"
      ;;
      --passwd=*)
        passwd="${_PARAMETER#--passwd=}"
        [ -n "${passwd}" ] && DEFAULT_PAWD="${passwd}"
      ;;
      --master=*)
        master="${_PARAMETER#--master=}"
        [ -n "${master}" ] && MASTER_IP="${master}"
      ;;
      --help|-h)
        clear
        options=( "--port=[2014]@port for dante socks5 server" \
                  "--ip=@Socks5 Server Ip address" \
                  "--user=@Socks5 Auth user" \
                  "--passwd=@Socks5 Auth passwd"\
                  "--master=@Socks5 Atuth IP" \
                  "--help,-h@print help info" )
        printf "Usage: %s [OPTIONS]\n\nOptions:\n\n" $0
          
        for option in "${options[@]}";do
          printf "  %-20s%s\n" "$( echo ${option} | sed 's/@.*//g')"  "$( echo ${option} | sed 's/.*@//g')"
        done
        echo -e "\n"
        exit 1
      ;;
      *)
          exit 1
      ;;
        
    esac
done

###########################################################################################################################

genconfig(){
  # CONFIGFILE $IP $PORT $INTERFACE
  CONFIGFILE=$1
  IP=$2
  PORT=$3
  INTERFACE=$4
  cat >> $CONFIGFILE <<EOF
# interface ${INTERFACE}
internal: ${IP}  port = ${PORT}
external: ${IP}

EOF
}

path=$(cd `dirname $0`;pwd )
( [ -n "$(grep CentOS /etc/issue)" ] \
  && ( yum install gcc g++ make vim pam-devel tcp_wrappers-devel unzip httpd-tools -y ) ) \
  || ( [ -n "$(grep -E 'Debian|Ubuntu' /etc/issue)" ] \
  && ( apt-get update ) \
  && ( apt-get install gcc g++ make vim libpam-dev libwrap0-dev unzip apache2-utils -y ) )\
  || exit 0
#&& ( apt-get purge dante-server -y ) \

useradd sock -s /bin/false > /dev/null 2>&1
#echo sock:sock | chpasswd
mkdir -p /etc/danted
CONFIGFILE="/etc/danted/sockd.conf"
cp /dev/null ${CONFIGFILE}

echo "$SERVERIP" | while read theip;do
  echo "Adding Interface :${theip}"
  port=$DEFAULT_PORT
  intface=$(ifconfig | grep "$theip" -1 | sed -n 1p | awk '{print $1}' | sed 's/:/-/g')
    
  if [ -z "$intface" ];then
      defaultip=$(echo "${Getserverip}" | head -1)
      intface=$(ifconfig | grep "$defaultip" -1 | sed -n 1p | awk '{print $1}' | sed 's/:/-/g' )
      echo "Input error. use default ip: ${defaultip}"
      genconfig $CONFIGFILE $defaultip $port $intface
      break
  fi
  genconfig $CONFIGFILE $theip $port $intface
done

cat >> $CONFIGFILE <<EOF
external.rotation: same-same
method: pam none
clientmethod: none
user.privileged: root
user.notprivileged: sock
logoutput: /var/log/danted.log

client pass {
        from: 0.0.0.0/0  to: 0.0.0.0/0
}
client block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
}       

#------------ Master ------------------
pass {
        from: ${MASTER_IP} to: 0.0.0.0/0
        method: none
}       
#-------------------------------------
pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        protocol: tcp udp
        method: pam
        log: connect disconnect
}
block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect error
}
EOF

rm /tmp/danted -rf
mkdir -p /tmp/danted
cd /tmp/danted

#start-stop-daemon
if [ -z "$(command -v start-stop-daemon)" ];then
wget http://developer.axis.com/download/distribution/apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
tar zxvf apps-sys-utils-start-stop-daemon-IR1_9_18-2.tar.gz
gcc apps/sys-utils/start-stop-daemon-IR1_9_18-2/start-stop-daemon.c -o start-stop-daemon -o /usr/local/sbin/start-stop-daemon
fi
#libpam-pwdfile
if [ ! -s /lib/security/pam_pwdfile.so ];then
wget --no-check-certificate https://github.com/tiwe-de/libpam-pwdfile/archive/master.zip -O master.zip
unzip master.zip
cd libpam-pwdfile-master/
make && make install
cd ../
fi

if [ ! -s /etc/danted/sbin/sockd ] || [ -z "$(/etc/danted/sbin/sockd -v | grep "$VERSION")" ];then
wget http://www.inet.no/dante/files/dante-1.3.2.tar.gz
tar zxvf dante*
cd dante*
./configure --with-sockd-conf=${CONFIGFILE} --prefix=/etc/danted
make && make install
cd ../../
fi
#Complile Done
rm /tmp/danted -rf

cat > /etc/pam.d/sockd  <<EOF
auth required pam_pwdfile.so pwdfile /etc/danted/sockd.passwd
account required pam_permit.so
EOF
/usr/bin/htpasswd -c -d -b /etc/danted/sockd.passwd ${DEFAULT_USER} ${DEFAULT_PAWD}

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
VERSION="1.3.2"
DESC="Dante SOCKS daemon"
PIDFILE="/var/run/sockd.pid"
CONFIGFILE=/etc/danted/sockd.conf

test -f $DAEMON || exit 0
test -f $CONFIGFILE || exit 0

set -e
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
#Color Variable

start_daemon_all(){
      LOGFILE=$(grep '^logoutput' ${CONFIGFILE} | sed 's/.*logoutput: \(.*\).*/\1/g')

      if [ -s $PIDFILE ] && [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ];then
           echo -e "${CRED}Danted Server [ Runing;Failed ] ${CEND}" 
           return 0
      fi

      cp /dev/null $PIDFILE
      cp /dev/null $LOGFILE

      if ! egrep -cve '^ *(#|$)' \
         -e '^(logoutput|user\.((not)?privileged|libwrap)):' $CONFIGFILE > /dev/null
      then
          echo -e "${CRED}Danted Server [ not configured ] ${CEND}"
          return 0
      fi

      start-stop-daemon --start --quiet --background --oknodo --pidfile $PIDFILE \
                --exec $DAEMON -- -f ${CONFIGFILE} -D -p $PIDFILE -N 1 -n
      sleep 2
      
      if [ -s $PIDFILE ];then
          echo -e "${CGREEN}Danted Server [ Runing ] ${CEND}"
      else
          echo -e "${CRED}Danted Server [ Start Faild ] ${CEND}"
      fi
}
stop_daemon_all(){
    if [ ! -s $PIDFILE ];then 
          echo -e "${CRED}Danted Server [ PID.LOST;Unable ] ${CEND}"
    fi
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE \
    --exec $DAEMON -- -f ${CONFIGFILE} -p $PIDFILE -N 1 -n

    ( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] && \
      echo -e "${CRED}Danted Server [ Stop Failed ] ${CEND}" ) || \
      echo -e "${CYELLOW}Danted Server [ Stop Done ] ${CEND}"
}
force_stop_daemon(){
    ps -ef | grep 'sockd' | grep -v 'grep' | awk '{print $2}' | while read pid; do kill -9 $pid > /dev/null 2>&1 ;done
}

reload_daemon_all(){
    if [ -s $PIDFILE ];then
      if [ -z "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ];then
        echo -e "${CRED}Danted Server [ PID.DIE;Unable ] ${CEND}"  
        continue
      fi
   else
        echo -e "${CRED}Danted Server [ PID.LOST;Unable ] ${CEND}" 
        continue
    fi
        start-stop-daemon --stop --signal 1 --quiet --oknodo --pidfile $PIDFILE \
    --exec $DAEMON -- -f $CONFIGFILE -p $PIDFILE -N 1 -n

    ( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] \
      && echo -e "${CGREEN}Danted Server [ Runing ] ${CEND}" ) \
      || echo -e "${CRED}Danted Server [ Failed ] ${CEND}"

}
status_daemon_all(){
    printf "%s\n" "${CCYAN}+-----------------------------------------+$CEND"

    if [ ! -s $PIDFILE ];then
      printf "%s\n" "${CRED} Danted Server [ Stop ] ${CEND}"
    else
      ( [ -n "$( ps aux | awk '{print $2}'| grep "^$(cat $PIDFILE)$" )" ] \
      && printf "%s\n" "${CGREEN} Danted Server [ Runing ] ${CEND}" ) \
      || printf "%s\n" "${CRED} Danted Server [ PID.DIE;Running ] ${CEND}"
    fi

    printf "%s\n" "${CCYAN}+-----------------------------------------+$CEND"
    printf "%-30s%s\n"  "${CGREEN} Dante Version:${CEND}"  "$CMAGENTA ${VERSION}${CEND}"
    printf "%-30s\n"  "${CGREEN} Socks5 Info:${CEND}"

    grep '^internal:' ${CONFIGFILE} | \
    sed 's/internal:[[:space:]]*\([0-9.]*\).*port[[:space:]]*=[[:space:]]*\(.*\)/\1:\2/g' | \
        while read proxy;do
          printf "%20s%s\n" "" "${CMAGENTA}${proxy}${CEND}"
        done
    
    SOCKD_USER=$(cat /etc/danted/sockd.passwd | while read line;do echo $line| sed 's/\(.*\):.*/\1/';done)
    printf "%-30s%s\n" "${CGREEN} Socks5 User:${CEND}"  "$CMAGENTA ${SOCKD_USER}${CEND}"
    printf "%s\n" "${CCYAN}+_________________________________________+$CEND"
}
add_user(){
    User=$1
    Passwd=$2
    ( [ -z "$User" ] || [ -z "$Passwd" ] ) && echo " Error: User or password can't be blank" && return 0 
    /usr/bin/htpasswd -d -b /etc/danted/sockd.passwd ${User} ${Passwd}
}
del_uer(){
    User=$1
    [ -z "$User" ] && echo " Error: User Name can't be blank" && return 0 
    /usr/bin/htpasswd -D /etc/danted/sockd.passwd ${User}
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
    force_stop_daemon
    sleep 1
    start_daemon_all
  ;;
  status)
    clear
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
rm /usr/bin/danted -f
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
${CGREEN} Dante Version:       $CMAGENTA ${VERSION}$CEND
${CGREEN} Socks5 Info:         $CMAGENTA$CEND
EOF
 echo "${SERVERIP}" | while read theip;do
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
