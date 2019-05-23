### Delta-syncrepl Consumer configuration

##### 修改配置
ldapmodify -Y EXTERNAL  -H ldapi:/// -f hdb_config.ldif  

ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor_config.ldif  

ldapadd -x -D cn=manager,dc=luqimin,dc=cn -W -f base.ldif  

ldapmodify -Y external -H ldapi:/// -f log_enable.ldif  

ldapmodify -Y external -H ldapi:/// -f tls.ldif  

ldapadd -Y EXTERNAL  -H ldapi:/// -f module.ldif  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f consumer-sync.ldif  

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f consumer-sync-tls.ldif

##### 验证配置
ldapsearch -LLL -Q -Y EXTERNAL -H ldapi:/// -b cn=config dn | grep modul  

ldapsearch -LLL  -Y  EXTERNAL -H ldapi:/// -b cn=module{0},cn=config  

ldapsearch -x -LLL -W -D cn=manager,dc=luqimin,dc=cn -s base -b dc=luqimin,dc=cn contextCSN
