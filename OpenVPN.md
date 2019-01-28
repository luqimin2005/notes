## OpenVPN
---

#### 服务端
1、安装 OpenVPN
```
$ sudo apt install openvpn
```
2、安装工具 easy-rsa
```
$ git clone https://github.com/OpenVPN/easy-rsa.git
```
3、定义变量
```
$ cd easy-rsa/easyrsa3/
$ cp vars.example vars
$ vim vars
set_var EASYRSA_REQ_COUNTRY     "CN"
set_var EASYRSA_REQ_PROVINCE    "GD"
set_var EASYRSA_REQ_CITY        "SZ"
set_var EASYRSA_REQ_ORG         "SLF"
set_var EASYRSA_REQ_EMAIL       "admin@example.com"
set_var EASYRSA_REQ_OU          "PRI"
```
4、初始化
```
$ ./easyrsa init-pki
```
5、创建根证书 ca
```
$ ./easyrsa build-ca nopass
```
6、创建服务器端证书 server
```
$ ./easyrsa gen-req server nopass
```
7、签名证书
```
$ mv pki/reqs/server.req pki/reqs/server2.req
$ ./easyrsa import-req pki/reqs/server2.req server
$ ./easyrsa sign-req server server

```
8、创建 Diffie-Hellman
```
$ ./easyrsa gen-dh
$ openvpn --genkey --secret ta.key
```
9、复制证书文件到 /etc/openvpn
```
$ sudo cp pki/private/server.key /etc/openvpn/  
$ sudo cp pki/ca.crt /etc/openvpn/  
$ sudo cp pki/issued/server.crt /etc/openvpn/  
$ sudo cp ta.key /etc/openvpn/  
$ sudo cp pki/dh.pem /etc/openvpn/
```

#### 客户端
1、创建工作目录
```
$ mkdir -p ~/client-configs/keys  
$ sudo chmod -R 700 ~/client-configs
```
2、创建客户端证书，并签名
```
$ ./easyrsa gen-req client1 nopass
$ cp pki/private/client1.key ~/client-configs/keys/
$ mv pki/reqs/client1.req pki/reqs/client.req
$ ./easyrsa import-req pki/reqs/client.req client1
$ ./easyrsa sign-req client client1
```
3、复制证书文件到工作目录
```
$ cp pki/issued/client1.crt ~/client-configs/keys/
$ cp ta.key ~/client-configs/keys/
$ cp pki/ca.crt ~/client-configs/keys/
```

#### 启动服务
1、准备配置文件 /etc/openvpn
```
$ sudo vim /etc/sysctl.conf 
net.ipv4.ip_forward = 1
$ sudo sysctl -p
$ sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
$ sudo gzip -d /etc/openvpn/server.conf.gz
$ sudo vim /etc/openvpn/server.conf
port xxxx
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key  
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
tls-auth ta.key 
key-direction 0
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
```
2、配置 NAT
```
$ sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j SNAT --to-source 172.31.32.145
```
3、启动服务
```
$ sudo systemctl start openvpn@server
$ sudo systemctl enable openvpn@server
```

#### 配置客户端
1、准备客户端配置文件
```
$ mkdir -p ~/client-configs/files
$ chmod 700 ~/client-configs/files
$ cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
$ vim ~/client-configs/base.conf 
client
dev tun
proto udp
remote ec2-3-112-1-46.ap-northeast-1.compute.amazonaws.com 4869
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-CBC
verb 3
auth SHA256
key-direction 1
```
2、创建客户端证书
```
$ vim ~/client-configs/make_config.sh
$ chmod 700 ~/client-configs/make_config.sh
$ cd ~/client-configs
$ ./make_config.sh client1
```
3、安装客户端，并导入文件 client1.ovpn
```
URL: https://swupdate.openvpn.org/community/releases/openvpn-install-2.4.6-I602.exe
```