#!/bin/bash
# openldap configurate for mirroe mode.
# for the first instance.
# serverId set "1" by default.
# Usage: ./install.sh -d example.com \
#                     -m ldap-1.example.com \
#                     -r ldap-2.example.com \
#                     -a manager \
#                     -p password

function usage(){
    echo ""
    echo "Usage: ./install.sh -d example.com -m master.example.com -r replica.example.com -a manager -p password"
    echo "Options:"
    echo "        -d: domain name"
    echo "        -m: hostname of the server"
    echo "        -r: hostname of the replica"
    echo "        -a: ldap admin dn name"
    echo "        -p: ldap admin password"
}

while getopts d:m:s:a:p: opt; do
    case $opt in
        d)
            DOMAIN=$OPTARG
            ;;
        m)
            MASTER=$OPTARG
            ;;
        r)
            REPLICA=$OPTARG
            ;;
        a)
            ADMIN=$OPTARG
            ;;
        p)
            PASSWORD=$OPTARG
            ;;
        \?)
            echo "UNKNOW OPTION: $opt"
            usage
            exit 110
            ;;
    esac
done

if [ $DOMAIN ] && [ $MASTER ] && [ $REPLICA ] && [ $ADMIN ] && [ $PASSWORD ]; then
    echo "OpenLdap instance installation beginning..."
else
    echo "one or more options not found, please check..."
    usage
fi

# DOMAIN   =  luqimin.cn
# MASTER   =  master.luqimin.cn
# REPLICA  =  replica.luqimin.cn
# ADMIN    =  manager
# PASSWORD =  password

BASE_DN="dc="${DOMAIN//./,dc=}
ROOT_DN="cn=$ADMIN,$BASE_DN"
ROOT_PW=$(slappasswd -h {MD5} -s $PASSWORD)


echo "##### Install packages for openldap and mit kdc #####"
yum -y install openldap openldap-clients openldap-servers krb5-server krb5-server-ldap krb5-workstation

echo "##### Initialize configurations and start service #####"
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
mkdir ldifs/
cat > ldifs/openldap-init.ldif <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: BASE_DN
-
replace: olcRootDN
olcRootDN: ROOT_DN
-
replace: olcRootPW
olcRootPW: ROOT_PW

dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="ROOT_DN" read by * none
EOF

sed -i s/BASE_DN/$BASE_DN/g ldifs/openldap-init.ldif
sed -i s/ROOT_DN/$ROOT_DN/g ldifs/openldap_init.ldif
sed -i s/ROOT_PW/$ROOT_PW/g ldifs/openldap_init.ldif

ldapmodify -Y EXTERNAL  -H ldapi:/// -f openldap_init.ldif

# 测试配置文件，并重启服务
slaptest -u
systemctl restart slapd
systemctl enable slapd

echo "##### Loading baseDN and requied accounts #####"

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
cp -f basedn-demo.ldif ldifs/basedn.ldif
ldapadd -x -D $ROOT_DN -w $ROOT_PW -f ldifs/basedn.ldif

# 启用日志功能
echo "##### Enable logging for slapd ######"
cat > ldifs/log.ldif <<EOF
dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: stats sync
EOF

ldapmodify -Y external -H ldapi:/// -f ldifs/log.ldif

# 修改 rsyslog 配置文件，以记录独立的日志文件
echo "local4.*          /var/log/openldap.log" >> /etc/rsyslog.conf

systemctl restart rsyslog
systemctl restart slapd

# 安装CA，并签署证书
echo "##### Configurate CA and enable TLS for slapd #####"



# 加载镜像模式配置文件
cp -f mirror-demo.ldif ldifs/mirrot.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f ldifs/mirror.ldif