# Sockd
**Dante socks5 server (v1.3.2/v1.4.2) auto-install and management script** 

## About
To build a socks5 server, we have lots of open-source programs to reach that, [Dante](https://www.inet.no/dante/) is one of them.
I have been using Dante for years and starting to write this auto-install and management script two years ago.
This is the second update to match the systemd and new OS release like Debian 8 , CentOS 7.

Comparing with the apt-get or building from source manually, this script will benefit you bellow

* Auto-recognize, detect the machine's system automatically and compile from source code.
* Auto-config, check the system's network or read from argument to auto-generate config file.
* Same-rotation, in multi-ipaddr system. It works like when using different ip address to connect socks5, your external ip address will be different. That's the main reason why I using Dante for years.
* Multi-authorization, you can configure authorization by pam, system or using whitelist.
* Docker support [New]
* Support Dante Latest version 1.4.2 [New]

## Install by Docker

### Docker Run

```bash
# sockd.passwd is a `htpasswd` file contains socks5 auth user/password. 
docker run -d \
    --name sockd \
    --publish 2020:2020 \
    --volume sockd.passwd:/home/danted/conf/sockd.passwd \
    lozyme/sockd
```

### Docker Compose

#### Generate compose

```yaml
#
# wget https://raw.githubusercontent.com/Lozy/danted/dev/docker/docker-compose.yaml
#
version: '3'

services:

  sockd:
    image: lozyme/sockd
    container_name: sockd
    restart: always
    ports:
      - 2020:2020
    volumes:
      - sockd.passwd:/home/danted/conf/sockd.passwd
      # - sockd.conf:/home/danted/conf/sockd.conf
```

#### Run

```bash
docker-compose up -d
```

#### Check

```bash
ss -lnp | grep 2020
```

#### User Show/Add/Modify/Delete

> You should run bellow to change default password

```bash
docker exec sockd script/pam add sockd sockd
```

> more command you could use

```bash
[Show]          $docker exec sockd script/pam show
[Add/Modify]    $docker exec sockd script/pam add USER PASSWORD
[Delete]        $docker exec sockd script/pam del USER
```

#### Verify

```bash
curl https://ifconfig.co --socks5 127.0.0.1:2020 --proxy-user sockd:sockd
```


## Install by Script

```bash
wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install.sh -O install.sh 
bash install.sh

# run with options: bash install.sh option1 option2
bash install.sh --ip="A.A.A.A:B.B.B.B" --port=2016 --user=sockd --passwd=sockd --whitelist="X.X.X.X/32"

```

* *if you want to uninstall, using this command*

```bash
bash install.sh --uninstall
```

* *if you want to add user*

```bash
/etc/init.d/sockd adduser USERNAME PASSWORD
```

## Options

| Long Option | Short Option | Value refer | description |
| :--- | :--- | --- | --- |
| --ip=                | | ip address list (a.a.a.a:b.b.b.b) *#change ';' to ':' * | Socks5 Server Ip address |
| --port=             | | Default: 2016| port for dante socks5 server |
| --version=          | | Default: 1.3.2 | dante server version, latest is 1.4.2 |
| --user=              | | Pam-Auth Username | Socks5 Auth user |
| --passwd=            | | Pam-Auth Password |Socks5 Auth passwd |
| --whitelist=         | | whitelist ip range (a.a.a.a/32:b.b.b.b/32) |Socks5 Auth IP list |
| --whitelist-url=     | | online white list file (url) | Socks Auth whitelist http online |
| --from-package       | -p    | --    | Install package from Bin package |
| --update-whitelist   | -u    | --    |  update white list |
| --force              | -f    | --    | force install sockd |
| --help               | -h    | --    | print help info |

## Management

| command | option | description |
| :--- | :--- | --- |
| service sockd start | /etc/init.d/sockd start | start socks5 server daemon |
| service sockd stop | /etc/init.d/sockd stop | stop socks5 server daemon |
| service sockd restart | /etc/init.d/sockd restart | restart socks5 server daemon |
| service sockd reload | /etc/init.d/sockd reload | reload socks5 server daemon |
| service sockd status | | systemd process status |
| service sockd state | /etc/init.d/sockd state | running state |
| service sockd tail | /etc/init.d/sockd tail | sock log tail |
| service sockd adduser | /etc/init.d/sockd adduser | add pam-auth user:  service sockd adduser NAME PASSWORD |
| service sockd deluser | /etc/init.d/sockd deluser | delete pam-auth user:  service sockd deluser NAME |


## Test Pass

| OS release | Platform | Provider | Result |
| :--- | :--- | --- |  --- | 
| Debian GNU/Linux 8 (jessie) | x86_64 | vultr | pass |
| Debian GNU/Linux 7 (wheezy) | x86_64 | vultr | pass |
| Debian GNU/Linux 7 (wheezy) | i686 | vultr | pass |
| Ubuntu 16.10 (Yakkety Yak)  | x86_64 | vultr | pass |
| Ubuntu 14.04.5 LTS | i686 | vultr | pass
| CentOS Linux 7 (Core) | x86_64 | vultr | pass |
| CentOS Linux 6 | x86_64 | vultr | pass |
| CentOS Linux 6 | i686 | vultr | pass |
