#!/bin/bash

yum -y install openldap openldap-clients openldap-servers krb5-server krb5-server-ldap krb5-workstation

mkdir /var/lib/ldap/accesslog
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/accesslog/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /etc/openldap/
systemctl start slapd

if [ $? -eq 0 ]; then
    echo "slapd started, continue..."
else
    echo "slapd start failed, exit..."
    exit
fi

# 加载 Ldap 初始化配置
ldapmodify -Y EXTERNAL  -H ldapi:/// -f openldap_init.ldif

slaptest -u
systemctl restart slapd
systemctl enable slapd

# ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/core.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/collective.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/corba.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/duaconf.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/dyngroup.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/java.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/misc.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/openldap.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/pmi.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/ppolicy.ldif

# 加载 Base DN
ldapadd -x -D cn=manager,dc=luqimin,dc=cn -W -f base.ldif


cat > base.ldif << EOF
dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: stats sync
EOF

ldapmodify -Y external -H ldapi:/// -f log_enable.ldif


