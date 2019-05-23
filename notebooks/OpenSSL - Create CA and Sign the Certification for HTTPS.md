## 使用 OpenSSL 创建CA证书颁发机构，并为 HTTPS 颁发证书
#### 测试环境
| 角色 | 主机名 |
| --- | ---- |
| CA | sight-3.luqimin.cn |
| httpd | www.luqimin.cn |

### 创建一个 CA
1. 生成 ca 私钥文件： ca.key
    ```
    # cd /etc/pki/CA/  
    # openssl genrsa -aes256 -out private/ca.key 4096
    # chmod 400 private/ca.key
    ```
2. 生成 ca 的自签名证书： ca.crt
    ```
    # openssl req -new -x509 -days 3650 -sha256 -extensions v3_ca -key private/ca.key -out certs/ca.crt
    ```
3. 验证证书
    ```
    # openssl x509 -noout -text -in certs/ca.crt
    ```
### 为 http 服务颁发证书
1. 生成http服务私钥文件：http.key
    ```
    # openssl genrsa -out http.key 2048
    ```
2. 使用http服务私钥，生成证书请求文件：http.csr
    ```
    # openssl req -new -sha256 -key http.key -out http.csr
    ```
3. 将证书请求文件发送到CA服务器，并使用CA签名证书
    ```
    # cd /etc/pki/CA/  
    # openssl x509 -req -CA certs/ca.crt -CAkey private/ca.key -CAcreateserial -days 3650 -in http.csr -out http.crt
    Signature ok
    subject=/C=CN/ST=GD/L=Shenzhen/O=Web/OU=Httpd Server/CN=www.luqimin.cn/emailAddress=HttpdServer
    Getting CA Private Key
    Enter pass phrase for private/ca.key:
    ```
4. 验证证书
    ```
    # openssl verify -CAfile certs/ca.crt http.crt
    http.crt: OK
    ```
### 配置https服务
1. 安装 httpd 服务，以及 ssl 支持
    ```
    yum -y install httpd mod_ssl
    ```
2. 将 ca根证书文件、http私钥文件、http证书文件发送至http服务器
    * ca.crt
    * http.key
    * http.crt
3. 将证书文件路径添加到配置文件：/etc/httpd/conf.d/ssl.conf
    ```
    SSLCertificateKeyFile /root/http.key
    SSLCertificateFile /root/http.crt
    SSLCACertificateFile /root/ca.crt
    ```
4. 重启 httpd
    ```
    systemctl restart httpd
    ```