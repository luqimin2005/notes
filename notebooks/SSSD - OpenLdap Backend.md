## 配置 SSSD 集成 OpenLdap 进行 SSH 认证

### 测试环境
* LdapServer: hadoop03.cdp.luqimin.cn

### 配置步骤：
1. 安装依赖包
```
yum install sssd sssd-ldap nss-pam-ldapd openldap-clients oddjob-mkhomedir
```
2. 运行配置命令，启动 sssd 并集成 ldapauth
```
authconfig --enablesssd --enablesssdauth --enablerfc2307bis --disableforcelegacy \
           --enableldap --enableldapauth --disableldaptls --disablekrb5 \
           --ldapserver ldap://hadoop03.cdp.luqimin.cn --ldapbasedn "dc=cdp,dc=luqimin,dc=cn" \
           --enablemkhomedir --updateall
```
以上命令会自动修改 sssd.conf system-auth password-auth ldap.conf 等配置文件，并自动重启 sssd oddjobd sshd 等服务  
  
3. 修改配置文件 /etc/sssd/sssd.conf
```
# 由于没有配置证书，注释这一行，并添加 ldap_tls_reqcert = never
# ldap_tls_cacertdir = /etc/openldap/cacerts
# ldap_tls_reqcert = never

# 修改 ldap_schema  
ldap_schema = rfc2307

# 添加一个 bind_dn（任何可以正常连接 ldap 的用户即可），便于搜索用户和组
ldap_default_bind_dn = uid=zhangsan,ou=users,dc=cdp,dc=luqimin,dc=cn
ldap_default_authtok_type = password
ldap_default_authtok = 123456

# 添加用户和组的搜索属性
ldap_user_object_class = posixAccount
ldap_user_name = uid
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_group_name = cn
ldap_group_object_class = posixGroup
ldap_group_gid_number = gidNumber

# 在[nss]下添加
verride_homedir = /home/%u
override_shell = /bin/bash
```
4. 重启服务 sssd 和 oddjobd（用户登录时自动创建 home 目录）
```
systemctl restart sssd oddjobd
```
5. 验证
```
[root@hadoop03 ~]# id zhangsan
uid=24356(zhangsan) gid=54844(ops) groups=54844(ops)
[root@hadoop03 ~]#
[root@hadoop03 ~]# ssh zhangsan@hadoop03.cdp.luqimin.cn
The authenticity of host 'hadoop03.cdp.luqimin.cn (192.168.2.13)' can't be established.
ECDSA key fingerprint is SHA256:nMoYGX1rOxSmPCH5v55j2RNG3MuXLwwsmVTqO7p2enM.
ECDSA key fingerprint is MD5:de:4b:9c:db:6d:96:9e:dd:d7:54:dd:a8:26:42:2f:37.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'hadoop03.cdp.luqimin.cn,192.168.2.13' (ECDSA) to the list of known hosts.
zhangsan@hadoop03.cdp.luqimin.cn's password:
Creating home directory for zhangsan.
Last failed login: Sat Oct  8 16:55:35 CST 2022 from hadoop01.cdp.luqimin.cn on ssh:notty
There were 3 failed login attempts since the last successful login.
```
