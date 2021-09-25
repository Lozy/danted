# Sockd

基于 [Dante socks5 (1.3.2/1.4.2)](https://www.inet.no/dante) 的自动化部署镜像/脚本.

## Docker 安装模式

### 优势

+ 基于 Alpine, 精简镜像.
+ 支持 `Pam.user` 认证, 不与系统用户关联
+ 支持 一行命令启动


### 安装使用说明

#### 1. 使用 docker run

```bash
# sockd.passwd 是密码文件 
docker run -d \
    --name sockd \
    --publish 2020:2020 \
    --volume sockd.passwd:/home/danted/conf/sockd.passwd \
    lozyme/sockd
```

#### 2. 使用 docker-compose.yaml (定义用户密码文件路径 `CONFIGFILE`)

```yaml
version: '3'

services:

  sockd:
    image: lozyme/sockd
    container_name: sockd
    restart: always
    ports:
      - 2020:2020
    volumes:
      - CONFIGFILE:/home/danted/conf/sockd.passwd
```

#### 3. 启动

```bash
docker-compose up -d
```

#### 4. 检查端口

```bash
ss -lnp | grep 2020
```

#### 5. 添加用户

```bash
docker exec sockd script/pam add USER PASSWORD
```

#### 6. 查看用户

```bash
docker exec sockd script/pam show
```

#### 7. 验证 (外部访问需修改 127.0.0.1)

```bash
curl https://ifconfig.co --socks5 127.0.0.1:2020 --proxy-user sockd:sockd
```


## 自动安装脚本

### 安装选项

| 选项 | 描述 |
| ----- | ----- |
| --port= | socks5 端口号码 |
| --ip=: | 配置的IP地址，默认全部开启，使用:分格 |
| --version= | dante 版本, 默认 1.3.2, 最新 1.4.2 |
| --user= | pam认证用户名 |
| --passwd= | pam认证用户密码|
| --master= | 免认证地址，例如 github.com 或者 8.8.8.8/32 |
    
### 功能特点

+ 1. 采用dante稳定版本 1.3.2 编译安装 (也同时支持1.4.2)
+ 2. 自动识别系统IP（默认排除192.168.0.*， 10.0.0.*,127.0.0.*）,根据安装命令选择部分Ip或者全部IP安装(多IP环境)。
+ 3. 采用PAM 用户认证，认证不需要添加系统用户（默认添加进程用户sock），删除、添加用户方便，安全。
+ 4. sock5 运行状态查看,系统启动后自动加载。
+ 5. **完美支持多访问进出口（多IP的环境，支持 使用IP-1，访问网站IP查询为IP-1）**。
+ 6. 认证方式可选： 无用户名密码，系统用户名密码，Pam用户名密码
+ 7. 完美支持Centos/Debian,自动识别系统进行安装配置。[注意，经反馈，Centos 5 无法使用。]
+ 8. 自定义对连接客户端认证方式，支持白名单即支持某些IP/IP段无需认证即可连接。

### 已解决问题

+ 测试64位系统 centos 会出现认证失败 请添加一条命令 `cp /lib/security/pam_pwdfile.so /lib64/security/`


### 未解决问题

+ 1. 分析log对连接sock5的用户进行统计。

### 安装说明

#### 1. 下载

```
wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install.sh -O install.sh
```


#### 2. [可选] 修改 默认参数

```
DEFAULT_PORT 为默认端口
DEFAULT_USER PAM用户名
DEFAULT_PAWD PAM用户对应密码
MASTER_IP 为免认证白名单（域名，IP可选：  如默认的buyvm.info 或者具体Ip 8.8.8.8/32 ）
```

#### 3. 执行安装

```
bash install.sh
```

#### 4. 状态判断

+ 若运行结束后显示 Dante Server Install Successfuly! 则表明成功。
+ 若运行结束后显示 Dante Server Install Failed! 则表明安装失败，求留言反馈操作系统+具体问题。


### 使用说明

+ 1. 命令参数 `/etc/init.d/danted {start|stop|restart|status|add|del}`
+ 2. 重启sock5 `/etc/init.d/danted restart`  或者 `service danted restart`
+ 3. 关闭sock5 `/etc/init.d/danted stop` 或者 `service danted stop`
+ 4. 开启sock5 `/etc/init.d/danted start` 或者 `service danted start`
+ 5. 查看sock5状态 `/etc/init.d/danted status` 或者 `service danted status`
+ 6. 添加SOCK5 PAM用户/修改密码 `/etc/init.d/danted add 用户名 密码`
+ 7. 删除SOCK5 PAM用户 `/etc/init.d/danted del 用户名`
+ 8. 配置文件路径 `/etc/danted/sockd.conf`
+ 9. 日志记录路径 `/var/log/danted.log`
+ 10. danted 帮助命令 `danted --help`

### 注意事项

+ 1. 绝大部分浏览器（除了Opera）都不支持带密码认证的Socks5，所以使用电脑需要安装proxifier/proxycap 等软件做验证处理。
+ 2. 如果是固定IP/Ip 段 可以修改配置文件，设置白名单访问。


    - 进入 /etc/danted/ 找到配置文件
    - 修改 第一个pass {} 模块下的 `from: Master_IP/32 to: 0.0.0.0/0` . 把 `Master_IP/32` 修改为需要使用代理的Ip段/IP地址 如 `114.114.114.0/24` 或者 5`.5.5.5/32` . 多个访问源，请复制多个 client pass {} 模块
    - 重启Danted 进程 `service danted restart`

+ 3. 如需删除danted，请参考以下命令删除程序文件

    - `service danted stop`
    - `rm -rf /etc/danted/`
    - `rm -f /etc/init.d/danted<`

