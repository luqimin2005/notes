## 配置 OpenLdap 的 Delta-syncrepl 复制
* [参考链接](http://www.openldap.org/doc/admin24/replication.html#Delta-syncrepl)
#### 测试环境
| 角色 | 主机名 |
| ---- | ----- |
| CA | sight-3.luqimin.cn |
| Ldap Provider | sight-3.luqimin.cn |
| Ldap Consumer | sihgt-2.luqimin.cn | 

### Delta-syncrepl 配置（1/2）：Provider
* [配置文件](https://github.com/luqimin2005/notes/tree/master/notebooks/ldap-provider-ldifs)
1. 定义 module.ldif 文件，并加载 hdb backend、accesslog、syncprov
    ```
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b cn=config dn | grep module
    # vim module.ldif
    dn: cn=module{0},cn=config
    objectClass: olcModuleList
    cn: module{0}
    olcModulePath: /usr/lib64/openldap
    olcModuleLoad: {0}back_hdb
    olcModuleLoad: {1}accesslog.la
    olcModuleLoad: {2}syncprov.la
    ```
    加载 module.ldif
    ```
    # ldapadd -Y EXTERNAL  -H ldapi:/// -f module.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    adding new entry "cn=module{0},cn=config"
    ```
    检查配置已经被正确加载
    ```
    # ldapsearch -LLL  -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    dn: cn=module{0},cn=config
    objectClass: olcModuleList
    cn: module{0}
    olcModulePath: /usr/lib64/openldap
    olcModuleLoad: {0}back_hdb
    olcModuleLoad: {1}accesslog.la
    olcModuleLoad: {2}syncprov.la
    ```
2. 创建一个用于存储 accesslog 数据的数据库
    ```
    # mkdir -p /var/lib/ldap/accesslog
    # cp /var/lib/ldap/DB_CONFIG /var/lib/ldap/accesslog/
    # chown -R ldap:ldap /var/lib/ldap/accesslog
    ```
    定义 accesslog.ldif 文件，配置 Accesslog 数据库
    ```
    dn: olcDatabase=hdb,cn=config
    changetype: add
    objectClass: olcDatabaseConfig
    objectClass: olcHdbConfig
    olcDatabase: hdb
    olcDbDirectory: /var/lib/ldap/accesslog
    olcSuffix: cn=accesslog
    olcRootDN: cn=manager,dc=luqimin,dc=cn
    olcDbIndex: default eq
    olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart
    ```
    加载 accesslog.ldif
    ```
    # ldapmodify -Y EXTERNAL -H ldapi:/// -f accesslog.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    adding new entry "olcDatabase=hdb,cn=config"
    ```
    检查配置已被正确加载
    ```
    # ls -ltr /etc/openldap/slapd.d/cn\=config/
    ...
    olcDatabase={3}hdb.ldif
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={3}hdb,cn=config
    dn: olcDatabase={3}hdb,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcHdbConfig
    olcDatabase: {3}hdb
    olcDbDirectory: /var/lib/ldap/accesslog
    olcSuffix: cn=accesslog
    olcRootDN: cn=manager,dc=luqimin,dc=cn
    olcDbIndex: default eq
    olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart
    ```
3. 在 Accesslog 数据库上定义 Syncprov Overlay  
    定义 overlay-accesslog.ldif
    ```
    dn: olcOverlay=syncprov,olcDatabase={3}hdb,cn=config
    changetype: add
    objectClass: olcOverlayConfig
    objectClass: olcSyncProvConfig
    olcOverlay: syncprov
    olcSpNoPresent: TRUE
    olcSpReloadHint: TRUE
    ```
    加载 overlay-accesslog.ldif
    ```
    # ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f overlay-accesslog.ldif
    adding new entry "olcOverlay=syncprov,olcDatabase={3}hdb,cn=config"
    ```
    验证
    ```
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={3}hdb,cn=config
    dn: olcDatabase={3}hdb,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcHdbConfig
    olcDatabase: {3}hdb
    olcDbDirectory: /var/lib/ldap/accesslog
    olcSuffix: cn=accesslog
    olcRootDN: cn=manager,dc=luqimin,dc=cn
    olcDbIndex: default eq
    olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart

    dn: olcOverlay={0}syncprov,olcDatabase={3}hdb,cn=config
    objectClass: olcOverlayConfig
    objectClass: olcSyncProvConfig
    olcOverlay: {0}syncprov
    olcSpNoPresent: TRUE
    olcSpReloadHint: TRUE
    ```
4. 在主数据库上定义 Syncprov Overlay
    ```
    # 添加特定的索引：entryCSN、entryUUID
    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    add: olcDbIndex
    olcDbIndex: entryCSN eq
    -
    add: olcDbIndex
    olcDbIndex: entryUUID eq

    # 为主数据库配置 syncrepl Provider
    dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
    changetype: add
    objectClass: olcOverlayConfig
    objectClass: olcSyncProvConfig
    olcOverlay: syncprov
    olcSpCheckPoint: 500 15

    # 为主数据库定义 accesslog overlay
    # 每天扫描 accesslog 数据库，清除超过 7 天的条目
    dn: olcOverlay=accesslog,olcDatabase={2}hdb,cn=config
    changetype: add
    objectClass: olcOverlayConfig
    objectClass: olcAccessLogConfig
    olcOverlay: accesslog
    olcAccessLogDB: cn=accesslog
    olcAccessLogOps: writes
    olcAccessLogPurge: 7+00:00 1+00:00
    olcAccessLogSuccess: TRUE
    ```
    加载 overlay-primary.ldif 
    ```
    # ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f overlay-primary.ldif 
    modifying entry "olcDatabase={2}hdb,cn=config"
    adding new entry "olcOverlay=syncprov,olcDatabase={2}hdb,cn=config"
    adding new entry "olcOverlay=accesslog,olcDatabase={2}hdb,cn=config"
    ```
    验证
    ```
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={2}hdb,cn=config dn
    dn: olcDatabase={2}hdb,cn=config
    dn: olcOverlay={0}syncprov,olcDatabase={2}hdb,cn=config
    dn: olcOverlay={1}accesslog,olcDatabase={2}hdb,cn=config
    ```
5. 准备同步账号：cn=replicator,dc=luqimin,dc=cn，使用 replicator.ldif 文件定义
    ```
    dn: cn=replicator,dc=luqimin,dc=cn
    objectClass: simpleSecurityObject
    objectClass: organizationalRole
    cn: replicator
    description: OpenLDAP Replication User
    userPassword: {MD5}4QrcOUm6Wau+VuBX8g+IPg==
    ```
    加载 replicator.ldif
    ```
    # ldapadd -a -H ldapi:/// -f replicator.ldif -D "cn=manager,dc=luqimin,dc=cn" -W
    Enter LDAP Password: 
    adding new entry "cn=replicator,dc=luqimin,dc=cn"
    ```
6. 为同步账号配置权限
    配置 replicator 具有无限搜索的权限，定义 limits.ldif
    ```
    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    add: olcLimits
    olcLimits: dn.exact="cn=replicator,dc=luqimin,dc=cn" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
    
    dn: olcDatabase={3}hdb,cn=config
    changetype: modify
    add: olcLimits
    olcLimits: dn.exact="cn=replicator,dc=luqimin,dc=cn" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
    ```
    配置数据库的 acl 权限，定义 acls.ldif
    ```
    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    replace: olcAccess
    olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=manager,dc=luqimin,dc=cn" write by self write by anonymous auth by * none
    olcAccess: {1}to dn.base="" by anonymous auth by * none
    olcAccess: {2}to * by dn="cn=manager,dc=luqimin,dc=cn" write by dn="cn=readonly-user,ou=users,dc=luqimin,dc=com" read by dn="cn=replicator,dc=luqimin,dc=cn" read by anonymous auth by * none
    
    dn: olcDatabase={3}hdb,cn=config
    changetype: modify
    add: olcAccess
    olcAccess: {0}to * by dn="cn=manager,dc=luqimin,dc=cn" write by dn="cn=replicator,dc=luqimin,dc=cn" read by anonymous auth by * none
    ```
    加载 limits.ldif、acls.ldif
    ```
    # ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f limits.ldif
    modifying entry "olcDatabase={2}hdb,cn=config"
    modifying entry "olcDatabase={3}hdb,cn=config"

    # ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f acls.ldif 
    modifying entry "olcDatabase={2}hdb,cn=config"
    modifying entry "olcDatabase={3}hdb,cn=config"
    ```
    验证
    ```
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={2}hdb,cn=config olcAccess
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={3}hdb,cn=config olcAccess
    ```

### Delta-syncrepl 配置（2/2）：Consumer
* [配置文件](https://github.com/luqimin2005/notes/tree/master/notebooks/ldap-consumer-ldifs)
1. [参考文档：LDAP - New OpenLdap Instance](https://github.com/luqimin2005/notes/blob/master/notebooks/LDAP%20-%20New%20OpenLdap%20Instance.md) 在主机 sight-2.luqimin.cn 安装一个新的 Ldap 实例；  
    [参考文档：LDAP - Logging and StartTLS](https://github.com/luqimin2005/notes/blob/master/notebooks/LDAP%20-%20Logging%20and%20StartTLS.md) 为此 Ldap 实例开启日志功能，并启用 TLS 加密传输
2. 定义 module.ldif 文件，并加载 hdb backend、syncprov
    ```
    # ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b cn=config dn | grep module
    # vim module.ldif
    dn: cn=module{0},cn=config
    objectClass: olcModuleList
    cn: module{0}
    olcModulePath: /usr/lib64/openldap
    olcModuleLoad: {0}back_hdb
    olcModuleLoad: {1}syncprov.la
    ```
    加载 module.ldif
    ```
    # ldapadd -Y EXTERNAL  -H ldapi:/// -f module.ldif
    adding new entry "cn=module{0},cn=config"
    ```
    检查配置已经被正确加载
    ```
    # ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config
    dn: cn=module{0},cn=config
    objectClass: olcModuleList
    cn: module{0}
    olcModulePath: /usr/lib64/openldap
    olcModuleLoad: {0}back_hdb
    olcModuleLoad: {1}syncprov
    ```
3. 定义 consumer-sync.ldif，配置副本数据库，与 syncrepl 指令
    ```
    dn: olcDatabase={2}hdb,cn=config
    changetype: modify
    add: olcDbIndex
    olcDbIndex: entryUUID eq
    -
    add: olcSyncRepl
    olcSyncRepl: rid=0 provider=ldap://sight-3.luqimin.cn bindmethod=simple binddn="cn=replicator,dc=luqimin,dc=cn" credentials=123456 searchbase="dc=luqimin,dc=cn" logbase="cn=accesslog" logfilter="(&(objectClass=auditWriteObject)(reqResult=0))" schemachecking=on type=refreshAndPersist retry="60 +" syncdata=accesslog starttls=critical tls_reqcert=demand
    -
    add: olcUpdateRef
    olcUpdateRef: ldap://sight-3.luqimin.cn
    ```
    加载
    ```
    # ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f consumer-sync.ldif
    modifying entry "olcDatabase={2}hdb,cn=config"
    ```
4. 验证，两台服务器上运行以下命令，contextCSN 值一致表示已同步
    ```
    # ldapsearch -x -LLL -W -D cn=manager,dc=luqimin,dc=cn -s base -b dc=luqimin,dc=cn contextCSN
    Enter LDAP Password: 
    dn: dc=luqimin,dc=cn
    contextCSN: 20190523093943.151849Z#000000#000#000000

    ```

### 验证
