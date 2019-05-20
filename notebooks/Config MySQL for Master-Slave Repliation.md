## 配置MySQL的主从复制
* [参考链接](https://community.hortonworks.com/articles/92023/high-availability-for-mysql-database.html)

#### 测试环境信息：
* Master主机: sight-2.luqimin.cn
* Slave主机: sight-3.luqimin.cn
* MySQL版本: mysql-community-server.x86_64           5.7.26-1.el7

#### 先决条件：已配置MySQL正常运行

#### 配置步骤一：（sight-2.luqimin.cn）
1. 停止MySQL服务
```
     # systemctl stop mysqld
```
2. 编辑配置文件/etc/my.cnf，并添加如下参数
```
    [mysqld]
    datadir=/data/0/mysql
    socket=/var/lib/mysql/mysql.sock
    user=mysql
    innodb_file_per_table=1
    innodb_buffer_pool_size=4G
    innodb_flush_log_at_trx_commit=2
    innodb_flush_method=O_DIRECT
    log_bin=mysql-bin
    binlog_format=ROW
    server_id=10
    innodb_support_xa=1

    [mysqld_safe]
    log-error=/var/log/mysqld.log
    pid-file=/var/run/mysqld/mysqld.pid
```