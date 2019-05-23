### Delta-syncrepl Provider configuration

##### 修改配置
ldapmodify -Y EXTERNAL  -H ldapi:/// -f hdb_config.ldif  

ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor_config.ldif  

ldapadd -x -D cn=manager,dc=luqimin,dc=cn -W -f base.ldif  

ldapmodify -Y external -H ldapi:/// -f log_enable.ldif  

ldapmodify -Y external -H ldapi:/// -f tls.ldif  

ldapadd -Y EXTERNAL  -H ldapi:/// -f module.ldif  

ldapmodify -Y EXTERNAL -H ldapi:/// -f accesslog.ldif  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f overlay-accesslog.ldif  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f overlay-primary.ldif  

ldapadd -a -H ldapi:/// -f replication.ldif -D "cn=manager,dc=luqimin,dc=cn" -W  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f limits.ldif  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f acls.ldif

##### 验证配置
ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b cn=config dn | grep module  

ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b cn=module{0},cn=config  

ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={3}hdb,cn=config  

ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={2}hdb,cn=config dn  

ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={2}hdb,cn=config olcAccess  

ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b olcDatabase={3}hdb,cn=config olcAccess  

ldapsearch -x -LLL -W -D cn=manager,dc=luqimin,dc=cn -s base -b dc=luqimin,dc=cn contextCSN
