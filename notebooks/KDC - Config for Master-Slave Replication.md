## 配置MIT KDC的主从复制
* [参考链接](https://web.mit.edu/kerberos/krb5-devel/doc/admin/install_kdc.html)

### 测试环境
* 操作系统提供的软件包，CentOS Linux release 7.4.1708 (Core)
* Master KDC : sight-3.luqimin.cn
* Replica KDC: sight-2.luqimin.cn
* realm name : LUQIMIN.CN
* stash file : .k5.LUQIMIN.CN
* admin principal : admin/admin

### 配置步骤 1/3：（Master KDC）
1. 安装 krb5-server 与 krb5-workstation
    ```
    # yum -y install krb5-server krb5-workstation
    ```
2. 编辑配置文件 /etc/krb5.conf
    ```
    includedir /etc/krb5.conf.d/

    [logging]
      default = FILE:/var/log/krb5libs.log
      kdc = FILE:/var/log/krb5kdc.log
      admin_server = FILE:/var/log/kadmind.log

    [libdefaults]
      dns_lookup_realm = false
      dns_lookup_kdc = false
      ticket_lifetime = 24h
      renew_lifetime = 7d
      forwardable = true
      rdns = false
      default_realm = LUQIMIN.CN
      default_ccache_name = /tmp/krb5cc_%{uid}

    [realms]
      LUQIMIN.CN = {
        kdc = sight-3.luqimin.cn
        kdc = sight-2.luqimin.cn
        admin_server = sight-3.luqimin.cn
    }

    [domain_realm]
      .luqimin.cn = LUQIMIN.CN
      luqimin.cn = LUQIMIN.CN
    ```
3. 编辑配置文件 /var/kerberos/krb5kdc/kdc.conf
    ```
    [kdcdefaults]
      kdc_ports = 88
      kdc_tcp_ports = 88

    [realms]
      LUQIMIN.CN = {
        kadmind_port = 749
        max_life = 12h
        max_renewable_life = 7d
        master_key_type = aes256-cts
        acl_file = /var/kerberos/krb5kdc/kadm5.acl
        database_name = /var/kerberos/krb5kdc/principal
        key_stash_file = /var/kerberos/krb5kdc/.k5.LUQIMIN.CN
        dict_file = /usr/share/dict/words
        admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
        supported_enctypes = aes256-cts:normal aes128-cts:normal
    }

    [logging]
      # By default, the KDC and kadmind will log output using
      # syslog.  You can instead send log output to files like this:
      kdc = FILE:/var/log/krb5kdc.log
      admin_server = FILE:/var/log/kadmin.log
      default = FILE:/var/log/krb5lib.log
    ```
4. 编辑配置文件 /var/kerberos/krb5kdc/kadm5.acl
    ```
    */admin@LUQIMIN.CN	*
    ```
5. 使用命令 kdb5_util 创建 Kerberos 数据库，并使用参数 -s 将密码安装在 stash file（.k5.LUQIMIN.CN）中
    ```
    # kdb5_util create -r LQUIMIN.CN -s
    ```
6. 创建管理账号（Principal）
    ```
    # kadmin.local
    kadmin.local: addprinc admin/admin@LUQIMIN.CN
    ```
7. 启动 Kerberos KDC（krb5kdc） 与 管理守护进程（kadmin）
    ```
    # systemctl start krb5kdc
    # systemctl enable krb5kdc
    # systemctl start kadmin
    # systemctl enable kadmin
    ```
8. 验证服务状态
    ```
    # systemctl status krb5kdc
    # systemctl status kadmin
    # tail -f /var/log/krb5kdc.log
    # tail -f /var/log/kadmin.log
    # kinit admin/admin@LUQIMIN.CN
    ```
### 配置步骤 2/3：（Replica KDC）
1. 安装 krb5-server 与 krb5-workstation
    ```
    # yum -y install krb5-server krb5-workstation
    ```
2. 在为每个 KDC 创建主机认证 Principal
    ```
    # kadmin -p admin/admin@LUQIMIN.CN
    kadmin: addprinc -randkey host/sight-3.luqimin.cn
    NOTICE: no policy specified for "host/sight-3.luqimin.cn@LUQIMIN.CN"; assigning "default"
    Principal "host/sight-3.luqimin.cn@LUQIMIN.CN" created.

    kadmin: addprinc -randkey host/sight-2.luqimin.cn
    NOTICE: no policy specified for "host/sight-2.luqimin.cn@LUQIMIN.CN"; assigning "default"
    Principal "host/sight-2.luqimin.cn@LUQIMIN.CN" created.
    ```
3. 为这些主机Principal生成keytab文件，并安装至 /etc/krb5.keytab
    ```
    # kadmin -p admin/admin@LUQIMIN.CN
    kadmin: ktadd -k /tmp/sight-3.keytab host/sight-3.luqimin.cn
    kadmin: ktadd -k /tmp/sight-2.keytab host/sight-2.luqimin.cn
    kadmin: q
    # cp /tmp/sight-3.keytab /etc/krb5.keytab
    # scp /tmp/sight-2.keytab /etc/krb5.keytab
    ```
4. 同步配置文件  
    主从复制仅同步数据库文件，并不同步配置文件，我们需要手工复制 Master KDC 的配置文件到 Replica KDC:
    * krb5.conf
    * kdc.conf
    * kadm5.acl
    * .k5.LUQIMIN.CN
    ```
    # scp /etc/krb5.conf sight-2:/etc/krb5.conf
    # scp /var/kerberos/krb5kdc/kdc.conf sight-2:/var/kerberos/krb5kdc/kdc.conf
    # scp /var/kerberos/krb5kdc/kadm5.acl sight-2:/var/kerberos/krb5kdc/kadm5.acl
    # scp /var/kerberos/krb5kdc/.k5.LUQIMIN.CN sight-2:/var/kerberos/krb5kdc/.k5.LUQIMIN.CN
    ```
5. Kerberos 数据库通过 kpropd 进程从 Master 复制到 Replica，需要在 Replica KDC 的配置目录中，创建 kpropd.acl，并包含以下内容
    ```
    # cat kpropd.acl 
    host/sight-3.luqimin.cn@LUQIMIN.CN
    host/sight-2.luqimin.cn@LUQIMIN.CN
    ```
6. 在 Replica KDC 上，使用 xinetd 对 kpropd 服务进行托管  
    安装 xinetd 
    ```
    # yum -y install xinetd
    ```
    添加配置文件： /etc/xinetd.d/krb5_prop
    ``` 
    service krb5_prop
    {
        disable     = no
        socket_type = stream
        wait        = no
        user        = root
        server      = /usr/sbin/kpropd
    }
    ```
    启动 xinetd，并加入开机启动项
    ```
    # systemctl start xinetd
    # systemctl enable xinetd
    ```
7. 在 Master KDC 上创建数据库的 dump 文件，并手工传输到 Replica KDC
    ```
    # kdb5_util dump /var/kerberos/krb5kdc/replica_datatrans
    # kprop -f /var/kerberos/krb5kdc/replica_datatrans sight-2.luqimin.cn
    Database propagation to kerberos-1.mit.edu: SUCCEEDED
    ```
8. 使用脚本和cron任务，配置周期性的同步Kerberos数据库  
    创建脚本：/var/kerberos/krb5kdc/data_trans.sh
    ```
    #!/bin/sh
    MAILTO=""
    kdclist="sight-2.luqimin.cn"
    /usr/sbin/kdb5_util dump /var/kerberos/krb5kdc/replica_datatrans
    for kdc in $kdclist
    do
        /usr/sbin/kprop -f /var/kerberos/krb5kdc/replica_datatrans $kdc >> /var/log/kprop.log 2>&1
    done
    ```
    为脚本添加执行权限：
    ```
    # chmod +x /var/kerberos/krb5kdc/data_trans.sh
    ```
    配置 cron 任务，每分钟执行一次
    ```
    # crontab -e
    */1 * * * * /var/kerberos/krb5kdc/data_trans.sh
    ```
9. 在 Replica KDC 上查看日志，确认同步状态
    ```
    # tail -f /var/log/messages
    ...
    May 21 14:16:01 sight-2 xinetd[95122]: START: krb5_prop pid=128105 from=::ffff:192.168.100.59
    May 21 14:16:01 sight-2 kpropd[128105]: Connection from sight-3.luqimin.cn
    May 21 14:16:01 sight-2 xinetd[95122]: EXIT: krb5_prop status=0 pid=128105 duration=0(sec)
    ```
10. 在 Replica KDC 上启动 Kerberos KDC 服务
    ```
    # systemctl start krb5kdc
    # systemctl enable krb5kdc
    ```
### 配置步骤 3/3：（状态切换）
1. 如果 Master KDC 在正常运行状态，我们需要：
    * 关闭 kadmin 进程
    * 停止 cron 任务
    * 手工同步一次数据库，确保数据一致
2. 将 Replica KDC 设置为 Master KDC：
    * 移除 kpropd.acl，并启动 kadmin 进程
    * 设置 cron 任务，向其他 Replica KDC 同步数据库
    * 修改 krb5.conf 文件中 [realms] 的信息，将 admin_server 指向为新 Master KDC


### 数据库的增量同步  
* 对于大型站点，使用数据库的增量同步，可以减少服务器和网络的压力
* `须停止使用 xinetd 托管 kpropd 服务，停止以上步骤中的 cron 任务，增量更新必须使用 kpropd 的独立进程`
1. 在 Master KDC 的配置文件 kdc.conf 中添加如下参数：
    ```
    [realms]
      LUQIMIN.CN = {
        ...
        iprop_enable = true
        iprop_port = 754

        # 默认值为 1000， 最大值为 2500
        iprop_master_ulogsize = 1000
        # 默认值为 2分钟，1.17版本之前使用 iprop_slave_poll
        iprop_replica_poll = 1m
        # 默认值为 300，即 5分钟
        iprop_resync_timeout = 300
        ...
    ```
2. 为每个 KDC 主机创建 kiprop 主体，并添加到 /etc/krb5.keytab
    ```
    # admin -p admin/admin
    kadmin: addprinc -randkey kiprop/sight-2.luqimin.cn
    kadmin: ktadd kiprop/sight-2.luqimin.cn
    ```
3. 在 Master KDC 上，添加 kadm5.acl，kiprop 须具有 p 权限
    ```
    */admin@LUQIMIN.CN	*
    kiprop/sight-3.luqimin.cn@LUQIMIN.CN	p
    kiprop/sight-2.luqimin.cn@LUQIMIN.CN	p
    ```
4. 重启 Master KDC 服务： krb5kdc 与 kadmin
    ```
    # systemctl restart krb5kdc
    # systemctl restart kadmin
    ```
5. 在 Replica KDC 的配置文件 kdc.conf 中启动增量更新，并重启服务 krb5kdc
    ```
    # systemctl restart krb5kdc
    ```
6. 启动进程 kpropd，查看日志验证更新状态 /var/log/messages
    ```
    # kpropd
    # tail -f /var/log/messages
    ...
    May 21 16:03:01 sight-2 kpropd[16546]: Incremental updates: 2 updates / 1829 us
    ```