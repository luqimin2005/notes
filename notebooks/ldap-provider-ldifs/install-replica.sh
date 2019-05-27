#!/bin/bash
# openldap configurate for mirroe mode.
# for the first instance.
# serverId set "1" by default.
# Usage: ./install-replica.sh -d example.com \
#                             -m ldap-1.example.com \
#                             -r ldap-2.example.com \
#                             -a manager \
#                             -p password

function usage(){
    echo -e "\nUsage: ./install-replica.sh -d example.com -m master.example.com -r replica.example.com -a manager -p password"
    echo -e "Options:"
    echo -e "        -d: domain name"
    echo -e "        -m: hostname of the server"
    echo -e "        -r: hostname of the replica"
    echo -e "        -a: ldap admin dn name"
    echo -e "        -p: ldap admin password"
}

while getopts d:m:r:a:p: opt; do
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
            echo -e "\033[31mERROR: UNKNOW OPTION: $opt\033[0m"
            usage
            exit 110
            ;;
    esac
done

if [ $DOMAIN ] && [ $MASTER ] && [ $REPLICA ] && [ $ADMIN ] && [ $PASSWORD ]; then
    echo -e "\033[32mINFO: OpenLdap instance installation beginning...\033[0m"
else
    echo -e "\033[31mERROR: One or more options not found, please check...\033[0m"
    usage
    exit 110
fi

# DOMAIN   =  luqimin.cn
# MASTER   =  master.luqimin.cn
# REPLICA  =  replica.luqimin.cn
# ADMIN    =  manager
# PASSWORD =  password

BASE_DN="dc="${DOMAIN//./,dc=}
ROOT_DN="cn=$ADMIN,$BASE_DN"

echo -e "\033[33m\n##### Install packages for openldap and mit kdc #####\033[0m"
yum -y install openldap openldap-clients openldap-servers krb5-server krb5-server-ldap krb5-workstation

echo -e "\033[33m\n##### Initialize configurations and start service #####\033[0m"
mkdir /var/lib/ldap/accesslog
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/accesslog/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /etc/openldap/

systemctl start slapd

if [ $? -eq 0 ]; then
    echo "INFO: Service slapd started, continue..."
else
    echo "ERROR: Service slapd start failed, exit..."
    exit
fi

# 加载 Ldap 初始化配置
mkdir ldifs/

cat > ldifs/openldap-init.ldif <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $BASE_DN
-
replace: olcRootDN
olcRootDN: $ROOT_DN
-
replace: olcRootPW
olcRootPW: $(slappasswd -h {MD5} -s $PASSWORD)

dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="$ROOT_DN" read by * none
EOF

ldapmodify -Y EXTERNAL  -H ldapi:/// -f ldifs/openldap-init.ldif

# 测试配置文件，并重启服务
slaptest -u
systemctl restart slapd

echo -e "\033[33m\n##### Loading baseDN and requied accounts #####\033[0m"
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
# cp -f basedn-demo.ldif ldifs/basedn.ldif
DEFAULT_PASSWORD="luqimin1"
cat > ldifs/basedn.ldif <<EOF
# defined baseDN
dn: $BASE_DN
objectclass: dcObject
objectclass: organization
o: describe
dc: $(echo $DOMAIN | cut -d . -f1)
EOF

ldapadd -x -D $ROOT_DN -w $PASSWORD -f ldifs/basedn.ldif

# 启用日志功能
echo -e "\033[33m\n##### Enable logging for slapd ######\033[0m"
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
echo -e "\033[32m\nService slapd started.\033[0m"

# 安装CA，并签署证书
echo -e "\033[33m\n##### Configurate CA and enable TLS for slapd #####\033[0m"
# tar -czf $REPLICA.pre /etc/pki/CA/certs/ca.crt /etc/pki/CA/$REPLICA.*

tar -xvf $REPLICA.pre -C ldifs/
mv /etc/krb5.conf /etc/krb5.conf.bak
mv /var/kerberos/krb5kdc/kdc.conf /var/kerberos/krb5kdc/kdc.conf.bak
mv /var/kerberos/krb5kdc/kadm5.acl /var/kerberos/krb5kdc/kadm5.acl.bak
find ldifs/etc/ -type f -exec mv {} /etc/openldap/certs/ \;
find ldifs/var/ -type f -exec mv {} /var/kerberos/krb5kdc/ \;
mv /etc/openldap/certs/krb5.conf /etc/krb5.conf
chown -R ldap:ldap /etc/openldap/certs

cat > ldifs/tls.ldif <<EOF
dn: cn=config
changetype: modify
delete: olcTLSCACertificatePath

dn: cn=config
changetype: modify
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/ca.crt

dn: cn=config
changetype: modify
delete: olcTLSCertificateFile
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/$REPLICA.crt

dn: cn=config
changetype: modify
delete: olcTLSCertificateKeyFile
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/$REPLICA.key

dn: cn=config
changetype: modify
add: olcTLSVerifyClient
olcTLSVerifyClient: never
EOF

ldapmodify -Y external -H ldapi:/// -f ldifs/tls.ldif



# 加载镜像模式配置文件，ServerID=1
echo -e "\033[33m\n##### Loading mirror mode configurations ######\033[0m"
# cp -f mirror-demo.ldif ldifs/mirrot.ldif
cat > ldifs/mirror.ldif <<EOF
# defined serverId
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: 2

# defined cn=module,cn=config, load back_hdb/accesslog/syncprov
dn: cn=module,cn=config
changetype: add
objectClass: olcModuleList
cn: module{0}
olcModulePath: /usr/lib64/openldap
olcModuleLoad: {0}back_hdb
olcModuleLoad: {1}accesslog.la
olcModuleLoad: {2}syncprov.la

# configurate accesslog database
dn: olcDatabase=hdb,cn=config
changetype: add
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: hdb
olcDbDirectory: /var/lib/ldap/accesslog
olcSuffix: cn=accesslog
olcRootDN: $ROOT_DN
olcDbIndex: default eq
olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart

# defined syncprov overlay for accesslog database
dn: olcOverlay=syncprov,olcDatabase={3}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpNoPresent: TRUE
olcSpReloadHint: TRUE

# defined syncprov overlay for primary database
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcDbIndex
olcDbIndex: entryCSN eq
-
add: olcDbIndex
olcDbIndex: entryUUID eq

dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckPoint: 500 15

dn: olcOverlay=accesslog,olcDatabase={2}hdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcAccessLogConfig
olcOverlay: accesslog
olcAccessLogDB: cn=accesslog
olcAccessLogOps: writes
olcAccessLogPurge: 7+00:00 1+00:00
olcAccessLogSuccess: TRUE

# defined acls for replicate user - cn=replicator,$BASE_DN
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="$ROOT_DN" write by self write by anonymous auth by * none
olcAccess: {1}to dn.base="" by anonymous auth by * none
olcAccess: {2}to * by dn="$ROOT_DN" write by dn="cn=readonly-user,ou=users,$BASE_DN" read by dn="cn=replicator,$BASE_DN" read by anonymous auth by * none
-
add: olcLimits
olcLimits: dn.exact="cn=replicator,$BASE_DN" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited

dn: olcDatabase={3}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to * by dn="$ROOT_DN" write by dn="cn=replicator,$BASE_DN" read by anonymous auth by * none
-
add: olcLimits
olcLimits: dn.exact="cn=replicator,$BASE_DN" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited

# defined consumer sync and enable mirror mode
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=0 provider=ldap://$MASTER bindmethod=simple binddn="cn=replicator,$BASE_DN" credentials=$DEFAULT_PASSWORD searchbase="$BASE_DN" logbase="cn=accesslog" logfilter="(&(objectClass=auditWriteObject)(reqResult=0))" schemachecking=on type=refreshAndPersist retry="60 +" syncdata=accesslog starttls=critical tls_reqcert=demand
-
add: olcMirrorMode
olcMirrorMode: TRUE
EOF

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f ldifs/mirror.ldif

# 配置Kdc集成Ldap
echo -e "\033[33m##### Configurate KDC with OpenLdap Back-end #####\033[0m"

cp /usr/share/doc/krb5-server-ldap-*/kerberos.schema ./
echo "include kerberos.schema" > kerberos.conf
slaptest -f kerberos.conf -F ldifs/

#cat ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i 's/dn: cn={0}kerberos/dn: cn=kerberos,cn=schema,cn=config/g' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i 's/cn: {0}kerberos/cn: kerberos/g' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/structuralObjectClass/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/entryUUID/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/creatorsName/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/createTimestamp/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/entryCSN/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/modifiersName/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif
sed -i '/modifyTimestamp/d' ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f  ldifs/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif 

cat > ldifs/krb5-index.ldif <<EOF
dn: olcDatabase={2}hdb,cn=config
add: olcDbIndex
olcDbIndex: krbPrincipalName eq,pres,sub
EOF
ldapmodify -Y EXTERNAL  -H ldapi:/// -f ldifs/krb5-index.ldif

REALM=$(echo $DOMAIN | tr 'a-z' 'A-Z')
mkdir /etc/krb5.d/

# kdb5_ldap_util -D cn=admin,dc=luqimin,dc=com -w password -H ldapi:/// stashsrvpw -f /etc/krb5.d/service.keyfile cn=admin,dc=luqimin,dc=com
# kdb5_ldap_util -D $ROOT_DN -w $PASSWORD -H ldapi:/// stashsrvpw -f /etc/krb5.d/service.keyfile $ROOT_DN
# expect "$ROOT_DN":"
# send "$PASSWORD\r"

systemctl restart slapd
systemctl start krb5kdc
systemctl start kadmin
systemctl enable slapd
systemctl enable krb5kdc
systemctl enable kadmin

echo -e "\033[32mPlease transfer $REPLICA.pre to the directory of replica server where script is running.\033[0m"

