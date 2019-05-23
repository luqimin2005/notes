## 开启日志记录功能，使用TLS加密
#### 测试环境
| 角色 | 主机名 |
| ---- | ----- |
| CA | sight-3.luqimin.cn |
| Ldap Server | sight-3.luqimin.cn |

### 启用 OpenLdap 的日志功能
1. 定义 ldif 文件：log_enable.ldif
    ```
    dn: cn=config
    changetype: modify
    replace: olcLogLevel
    olcLogLevel: stats sync
    ```
2. 加载 log_enable.ldif
    ```
    # ldapmodify -Y external -H ldapi:/// -f log_enable.ldif
    ```
3. 编辑 rsyslog 的配置文件 /etc/rsyslog.conf，添加 openldap 的日志记录规则，重启 rsyslog 与 slapd 服务
    ```
    # vim /etc/rsyslog.conf
    ...
    local4.*                            /var/log/openldap.log
    ...
    # systemctl restart rsyslog
    # systemctl restart slapd
    ```