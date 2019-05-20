## 配置MySQL的主从复制
* [参考链接](https://community.hortonworks.com/articles/92023/high-availability-for-mysql-database.html)

    #### 测试环境信息：
    版本: mysql-community-server.x86_64           5.7.26-1.el7

    | 节点 | 主机名 |
    | ------ | ------------------ |
    | Master | sight-2.luqimin.cn |
    | Slave  | sight-3.luqimin.cn |

    #### 先决条件：已配置MySQL正常运行

#### 配置步骤 1/2：（sight-2.luqimin.cn）
1. 停止MySQL服务
    ```
    # systemctl stop mysqld
    ```
2. 编辑配置文件/etc/my.cnf，并添加如下参数
    ```
    [mysqld]
    symbolic-links=0
    validate_password=OFF
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
3. 启动MySQL服务，并查看Master状态：
    ```
    # systemctl start mysqld
    # mysql -uroot -p
    Enter password:
    mysql> show master status \G;
    *************************** 1. row ***************************
                File: mysql-bin.000002
            Position: 2351
        Binlog_Do_DB: 
    Binlog_Ignore_DB: 
    Executed_Gtid_Set: 
    1 row in set (0.00 sec)
    ```
4. 创建同步用户'repl'@'sight-3.luqimin.cn'，并授权
    ```
    mysql> grant replication slave, replication client on *.* to 'repl'@'sight-3.luqimin.cn' identified by 'Pa$$w0rd' ;
    ```
5. 使用mysqldump命令dump所有数据库到本地文件
    ```
    # mysqldump --single-transaction --all-databases --master-data=1 --host=sight-2.luqimin.cn >> dump.out -p
    ```
6. 将dump.out复制到Slave节点
    ```
    # scp dump.out sight-3:~/
    ```
#### 配置步骤 2/2：（sight-3.luqimin.cn）
1. 停止MySQL服务
    ```
    # systemctl stop mysqld
    ```
2. 编辑配置文件/etc/my.cnf，并添加如下参数
    ```
    [mysqld]
    symbolic-links=0
    validate_password=OFF
    datadir=/data/0/mysql
    socket=/var/lib/mysql/mysql.sock
    user=mysql

    innodb_file_per_table=1
    innodb_buffer_pool_size=4G
    innodb_flush_log_at_trx_commit=2
    innodb_flush_method=O_DIRECT

    log_bin = mysql-bin
    binlog_format = ROW
    server_id = 20
    relay_log = mysql-relay-bin
    log_slave_updates = 1
    read_only = 1

    [mysqld_safe]
    log-error=/var/log/mysqld.log
    pid-file=/var/run/mysqld/mysqld.pid
    ```
3. 启动MySQL服务，并加载数据dump.out
    ```
    # systemctl start mysqld
    # mysql --host=sight-3.luqimin.cn -p < dump.out
    # mysql -uroot -p
    Enter password:
    mysql> show databases;
    ```
4. 配置从sight-2.luqimin.cn的复制通道
    ```
    mysql> change master to master_host='sight-2.luqimin.cn', master_user='repl', master_password='Pa$$w0rd', master_log_file='mysql-bin.000002', master_log_pos=1285;
    ```
    `注意:`   
    
    `master_log_file与master_log_pos需要在节点sight-2上，通过执行mysql指令：“show master status;”查询得到`
5. 重启MySQL后，查询Slave状态
    ```
    # systemctl restart mysqld
    # mysql -uroot -p
    Enter password: 
    mysql> show slave status \G;
    *************************** 1. row ***************************
    Slave_IO_State: Waiting for master to send event
    Master_Host: sight-2.luqimin.cn
    Master_User: repl
    Master_Port: 3306
    Connect_Retry: 60
    Master_Log_File: mysql-bin.000002
    Read_Master_Log_Pos: 2351
    Relay_Log_File: mysql-relay-bin.000003
    Relay_Log_Pos: 1725
    Relay_Master_Log_File: mysql-bin.000002
    Slave_IO_Running: Yes
    Slave_SQL_Running: Yes
    ...
    Seconds_Behind_Master: 0
    ...

    ```
    `通过验证Seconds_Behind_Master为0来检查复制是否正常工作`
