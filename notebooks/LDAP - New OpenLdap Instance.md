## 配置 Ldap 实例

#### 测试环境

| 节点 | 主机名 |
| ---- | ---- |
| Server | sight-3.luqimin.cn |
| BaseDN | dc=luqimin,dc=cn |

#### 配置步骤
1. 安装软件包，并启动服务
    ```
    # yum -y install openldap openldap-clients openldap-servers
    # systemctl start slapd
    ```
2. 修改配置文件 `slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif` 中 `olcSuffix`、`olcRootDN`、`olcRootPW`，配置为我们自己的域名，这里我们使用 ldif 文件修改
    ```
    # cat hdb_config.ldif
    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    replace: olcSuffix
    olcSuffix: dc=luqimin,dc=cn

    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    replace: olcRootDN
    olcRootDN: cn=manager,dc=luqimin,dc=cn

    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    replace: olcRootPW
    olcRootPW: {MD5}ISMvKXpXpadDiUoOSoAfww==
    ```
    注意这里的 `olcRootPW` 我们使用以下命令生成：(`xxxxxx`为密码明文）
    ```
    # slappasswd -h {MD5} -s xxxxxx
    {MD5}ISMvKXpXpadDiUoOSoAfww==
    ```
    加载 `hdb_config.ldif`
    ```
    # ldapmodify -Y EXTERNAL  -H ldapi:/// -f hdb_config.ldif
    ```
3. 修改配置文件 `slapd.d/cn=config/olcDatabase={1}monitor.ldif` 中 `olcAccess`，配置为我们自己的名称，这里我们使用 ldif 文件进行修改
    ```
    # cat monitor_config.ldif
    dn: olcDatabase={1}monitor,cn=config
    changetype: modify
    replace: olcAccess
    olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=manager,dc=luqimin,dc=cn" read by * none
    ```
    加载 `monitor_config.ldif`
    ```
    # ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor_config.ldif
    ```
4. 准备数据库配置文件，并修改配置文件的所属用户和组为 `ldap`:`ldap`
    ```
    # cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    chown -R ldap:ldap /var/lib/ldap/
    chown -R ldap:ldap /etc/openldap/
    ```
5. 测试配置，并重启 `slapd` 服务
    ```
    # slaptest -u
    config file testing succeeded
    # systemctl restart slapd
    # systemctl enable slapd
    ```
6. 添加 schema
    ```
    # cd /etc/openldap/schema/
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f core.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f cosine.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f nis.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f collective.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f corba.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f duaconf.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f dyngroup.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f inetorgperson.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f java.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f misc.ldif
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f openldap.ldif 
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f pmi.ldif 
    # ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f ppolicy.ldif
    ```
7. 初始化 `BaseDN`，这里我们使用 ldif 文件
    ```
    # cat base.ldif
    dn: dc=luqimin,dc=cn
    objectclass: dcObject
    objectclass: organization
    o: describe
    dc: luqimin
    ```
    加载 `base.ldif`
    ```
    # ldapadd –x –D “cn=manager,dc=luqimin,dc=cn –W –f base.ldif
    ```
8. 验证
    ```
    [root@sight-3 openldap]# ldapsearch -b dc=luqimin,dc=cn -D cn=manager,dc=luqimin,dc=cn -W  -LLL
    Enter LDAP Password: 
    dn: dc=luqimin,dc=cn
    objectClass: dcObject
    objectClass: organization
    o: describe
    dc: luqimin
    ```