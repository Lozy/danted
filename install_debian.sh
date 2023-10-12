#!/bin/bash

SCRIPT_HOST="https://public.sockd.info"
PACKAGE_NAME="dante_1.3.2-1_$(uname -m).deb"
BIN_DIR="/etc/danted"
BIN_PATH="$BIN_DIR/sbin/sockd"
CONFIG_PATH="$BIN_DIR/sockd.conf"
BIN_SCRIPT="/etc/init.d/sockd"
DEFAULT_IPADDR=$(ip addr | grep 'inet ' | grep -Ev 'inet 127|inet 192\.168' | sed "s/[[:space:]]*inet \([0-9.]*\)\/.*/\1/")

install_dependencies() {
  apt-get update
  apt-get install -y build-essential checkinstall libwrap0-dev libpam0g-dev libssl-dev curl libc-ares-dev libpcre3-dev
}

install_dante() {
  # Download and extract Dante source code
  cd /tmp
  curl -LO "$SCRIPT_HOST/$PACKAGE_NAME"
  dpkg -i $PACKAGE_NAME
  rm -f $PACKAGE_NAME
}

generate_config() {
  cat > $CONFIG_PATH <<EOF
# Generate interface $DEFAULT_IPADDR
internal: $DEFAULT_IPADDR port = 2016
external: $DEFAULT_IPADDR

clientmethod: none
socksmethod: pam.username none

user.privileged: root
user.notprivileged: sockd

logoutput: /var/log/sockd.log

client pass {
  from: 0/0 to: 0/0
  log: connect disconnect
}
client block {
  from: 0/0 to: 0/0
  log: connect error
}
EOF
}

create_log_dir() {
  mkdir -p /var/log
  chmod 755 /var/log
}

create_user_and_group() {
  groupadd -f sockd
  useradd -g sockd sockd -s /bin/false
}

set_permissions() {
  chown -R sockd:sockd $BIN_DIR
  chmod -R 755 $BIN_DIR
}

create_init_script() {
  cat > $BIN_SCRIPT <<EOF
#!/bin/bash
#
# /etc/
create_init_script() {
  cat > $BIN_SCRIPT <<EOF
#!/bin/bash
#
# /etc/init.d/sockd
#

### BEGIN INIT INFO
# Provides:          sockd
# Required-Start:    \$local_fs \$network
# Required-Stop:     \$local_fs
# Should-Start:      \$remote_fs
# Should-Stop:       \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: sockd
# Description:       Dante Socks5 Server
### END INIT INFO

NAME=sockd
DAEMON=$BIN_PATH
CONFIG=$CONFIG_PATH
PIDFILE=$BIN_DIR/run/sockd.pid

. /lib/lsb/init-functions

[ -r /etc/default/\$NAME ] && . /etc/default/\$NAME

case "\$1" in
  start)
        log_daemon_msg "Starting SOCKS server" "\$NAME"
        start-stop-daemon --start --oknodo --pidfile \$PIDFILE --exec \$DAEMON -- -D -f \$CONFIG
        log_end_msg \$?
        ;;
  stop)
        log_daemon_msg "Stopping SOCKS server" "\$NAME"
        start-stop-daemon --stop --oknodo --pidfile \$PIDFILE
        log_end_msg \$?
        rm -f \$PIDFILE
        ;;
  reload|force-reload)
        log_daemon_msg "Reloading SOCKS server configuration" "\$NAME"
        start-stop-daemon --stop --signal HUP --oknodo --pidfile \$PIDFILE
        log_end_msg \$?
        ;;
  restart)
        \$0 stop
        \$0 start
        ;;
  status)
        status_of_proc -p \$PIDFILE \$DAEMON \$NAME && exit 0 || exit \$?
        ;;
  *)
        log_action_msg "Usage: /etc/init.d/\$NAME {start|stop|restart|reload|force-reload|status}"
        exit 2
        ;;
esac

exit 0
EOF
}

configure_dante() {
  generate_config
  create_log_dir
  create_user_and_group
  set_permissions
  create_init_script
}

case "$1" in
  install)
    install_dependencies
    install_dante
    configure_dante
    $BIN_SCRIPT start
    ;;
  uninstall)
    $BIN_SCRIPT stop
    rm -r $BIN_DIR
    groupdel sockd
    userdel sockd
    rm $BIN_SCRIPT
    ;;
  config)
    configure_dante
    $BIN_SCRIPT restart
    ;;
  start)
    $BIN_SCRIPT start
    ;;
  stop)
    $BIN_SCRIPT stop
    ;;
  restart)
    $BIN_SCRIPT restart
    ;;
  *)
    echo "Usage: $0 {install|uninstall|config|start|stop|restart}"
    exit 1
    ;;
esac

exit 0
