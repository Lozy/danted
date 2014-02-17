<h2>Danted Socks5 一键安装脚本</h2>

<h3>******功能特点</h3>
<ul>
<li>1. 采用最新稳定版本 1.4.0 编译安装。</li>
<li>2. 自动识别系统IP（默认排除192.168.0.*， 10.0.0.*,127.0.0.*）,检测多Ip时，进行交互式选择Ip配置（直接回车则全部配置）。</li>
<li>3. 采用Pam用户认证，认证不需要添加系统用户（默认添加进程用户sock），删除、添加用户方便，安全。</li>
<li>4. sock5 运行状态查看。</li>
<li>5. 系统启动后自动加载。</li>
<li>6. 认证方式可选： 无用户名密码，系统用户名密码，Pam用户名密码</li>
<li>7. 完美支持Centos/Debian,自动识别系统进行安装配置。</li>
<li>8. 自定义对连接客户端认证方式，支持设置某些Ip/IP段无需认证即可连接。</li>
</ul>
<h3>******未解决问题</h3>
<ul>
<li>1. 分析log对连接sock5的用户进行统计。</li>
<li>2. Ubuntu/Redhat 未进行测试。</li>
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
<li> 8. 配置文件路径/etc/danted/conf/ </li>
<li> 9. 日志记录路径 /var/log/danted.*.log</li>
<li> 10. danted 帮助命令 danted --help </li>
</ul>
<h3>******使用注意事项</h3>
<ul>
<li> 1. 绝大部分浏览器（除了Opera）都不支持带密码认证的Socks5，所以使用电脑需要安装proxifier/proxycap 等软件做验证处理。<、li> 
<li> 2. 如果是固定IP/Ip 段 可以修改配置文件，设置白名单访问。
<ol>
<li>进入 /etc/danted/conf/ 找到配置文件</li>
<li>修改 第一个client pass {} 模块下的 from: Master_IP/32 to: 0.0.0.0/0 . 把 Master_IP/32 修改为需要使用代理的Ip段/IP地址 如 114.114.114.0/24 或者 5.5.5.5/32 . 多个访问源，请复制多个 client pass {} 模块</li>
</ol>
</li>
<li>重启Danted 进程 service danted restart </li>
</ul>
