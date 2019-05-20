## MySQL主从状态切换（Slave->Master）

#### 配置步骤：（Slave）
1. 登录MySQL，并停止slave进程
    ```
    mysql> stop slave io_thread;
    ```
2. 检查Slave状态：
    ```
    mysql> show slave status \G;
    *************************** 1. row ***************************
    Slave_IO_State: 
    Master_Host: sight-2.luqimin.cn
    Master_User: repl
    Master_Port: 3306
    Connect_Retry: 60
    Master_Log_File: mysql-bin.000002
    Read_Master_Log_Pos: 2351
    ```
    `Slave_IO_State 为空`
3. 查看processlist状态，等待slave处理完所有剩余条目
    ```
    mysql> show processlist;
    +----+-------------+-----------+------+---------+------+--------------------------------------------------------+------------------+
    | Id | User        | Host      | db   | Command | Time | State                                                  | Info             |
    +----+-------------+-----------+------+---------+------+--------------------------------------------------------+------------------+
    |  1 | system user |           | NULL | Connect | 3703 | Slave has read all relay log; waiting for the slave I/O thread to update it | NULL             |
    |  5 | root        | localhost | NULL | Query   |    0 | starting                                               | show processlist |
    +----+-------------+-----------+------+---------+------+--------------------------------------------------------+------------------+
    2 rows in set (0.00 sec)
    ```
4. 修改配置文件/etc/my.cnf，设置read_only=0后，重启MySQL
    ```
    # vim /etc/my.cnf
    read_only = 0
    # systemctl restart mysqld
    ```
5. 登录MySQL停止、重置slave，并验证
    ```
    # mysql -uroot -p
    Enter password: 
    mysql> stop slave;
    mysql> reset slave;
    mysql> show slave status \G;
    Empty set (0.00 sec)
    ```
6. 检查数据库权限，确定原服务具有相应的权限使用此MySQL服务
    ```
    mysql> select user, host from mysql.user;
    ```
7. 重置master，验证数据库读写状态
    ```
    mysql> reset master;
    mysql> show variables like 'read_only';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | read_only     | OFF   |
    +---------------+-------+
    1 row in set (0.00 sec)
    ```
8. 切换服务至此MySQL实例
