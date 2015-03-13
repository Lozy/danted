<h2>Danted Socks5 一键安装脚本</h2>
<h3>******安装选项</h3>

| 选项 | 描述 |
| ----- | ----- |
| --port= | socks5 端口号码 |
| --ip=;; | 配置的IP地址，默认全部开启，使用;分格 |
| --user= | pam认证用户名 |
| --passwd= | pam认证用户密码|
| --master= | 免认证地址，例如 github.com 或者 8.8.8.8/32 |
    
<h3>******功能特点</h3>
<ul>
<li>1. 采用dante稳定版本 1.3.2 编译安装。</li>
<li>2. 自动识别系统IP（默认排除192.168.0.*， 10.0.0.*,127.0.0.*）,根据安装命令选择部分Ip或者全部IP安装(多IP环境)。</li>
<li>3. 采用PAM 用户认证，认证不需要添加系统用户（默认添加进程用户sock），删除、添加用户方便，安全。</li>
<li>4. sock5 运行状态查看,系统启动后自动加载。</li>
<li>5. <b>完美支持多访问进出口（多IP的环境，支持 使用IP-1，访问网站IP查询为IP-1）。</b></li>
<li>6. 认证方式可选： 无用户名密码，系统用户名密码，Pam用户名密码</li>
<li>7. 完美支持Centos/Debian,自动识别系统进行安装配置。[注意，经反馈，Centos 5 无法使用。]</li>
<li>8. 自定义对连接客户端认证方式，支持白名单即支持某些IP/IP段无需认证即可连接。</li>
</ul>
<h3>******已解决问题</h3>
<ul>
<li>测试64位系统 centos 会出现认证失败 请添加一条命令 <code>cp /lib/security/pam_pwdfile.so /lib64/security/ </code></li>
</ul>
<h3>******未解决问题</h3>
<ul>
<li>1. 分析log对连接sock5的用户进行统计。</li>
</ul>
<hr>
<h3>******安装用说明</h3>
<ul>
<li> 1. 下载 
<code> wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install.sh -O install.sh </code> </li>
<li> 2. [可选] 修改 默认参数，DEFAULT_PORT 为默认端口，DEFAULT_USER PAM用户名，DEFAULT_PAWD PAM用户对应密码 MASTER_IP 为免认证白名单（域名，IP可选：  如默认的buyvm.info 或者具体Ip 8.8.8.8/32 ）</li>
<li> 3. 修改后，执行 <code> bash install.sh </code> </li>
<li> 4. 若运行结束后显示 Dante Server Install Successfuly! 则表明成功。
<p>显示 Dante Server Install Failed! 则表明安装失败，求留言反馈操作系统+具体问题。</p></li>
</ul>
<h3>******安装后使用说明</h3>
<ul>
<li> 1. 命令参数 /etc/init.d/danted {start|stop|restart|status|add|del}</li>
<li> 2. 重启sock5 /etc/init.d/danted restart  或者 service danted restart </li>
<li> 3. 关闭sock5 /etc/init.d/danted stop 或者 service danted stop </li>
<li> 4. 开启sock5 /etc/init.d/danted start 或者 service danted start </li>
<li> 5. 查看sock5状态 /etc/init.d/danted status 或者 service danted status </li>
<li> 6. 添加SOCK5 PAM用户/修改密码 /etc/init.d/danted add 用户名 密码</li>
<li> 7. 删除SOCK5 PAM用户 /etc/init.d/danted del 用户名</li>
<li> 8. 配置文件路径/etc/danted/sockd.conf </li>
<li> 9. 日志记录路径 /var/log/danted.log</li>
<li> 10. danted 帮助命令 danted --help </li>
</ul>
<h3>******使用注意事项</h3>
<ul>
<li> 1. 绝大部分浏览器（除了Opera）都不支持带密码认证的Socks5，所以使用电脑需要安装proxifier/proxycap 等软件做验证处理。</li> 
<li> 2. 如果是固定IP/Ip 段 可以修改配置文件，设置白名单访问。</li>
<ol>
<li>进入 /etc/danted/ 找到配置文件</li>
<li>修改 第一个pass {} 模块下的 from: Master_IP/32 to: 0.0.0.0/0 . 把 Master_IP/32 修改为需要使用代理的Ip段/IP地址 如 114.114.114.0/24 或者 5.5.5.5/32 . 多个访问源，请复制多个 client pass {} 模块</li>
<li>重启Danted 进程 service danted restart </li>
</ol>
<li> 3. 如需删除danted，请参考以下命令删除程序文件</li>

<p><code>service danted stop</code></p>
<p><code>rm -rf /etc/danted/</code></p>
<p><code>rm -f /etc/init.d/danted</code></p>

</ul>
