## 安装一个 FreeIPA 实例

#### 测试环境
| 主机名 | IP地址 |
| - | - |
| ipa1.luqimin.cn | 172.17.2.51 |
| ipa2.luqimin.cn | 172.17.2.52 |

### 配置步骤
1. 配置主机环境，设置主机名、固定IP地址、DNS指向本机
```
hostnamectl set-hostname ipa1.luqimin.cn
hostname ipa1.luqimin.cn
nmcli conn show 
nmcli conn mod ens33 ipv4.addr 172.17.2.51/24 ipv4.gateway 172.17.2.1 ipv4.dns 172.17.2.51 ipv4.method manual
nmcli conn down ens33 && nmcli conn up ens33
```
2. 安装 freeIPA 软件包
```
yum -y install ipa-server ipa-server-dns

```
3. 准备参数配置 ipa-server
```
ipa-server-install --domain=luqimin.cn --realm=LUQIMIN.CN --ds-password=Cloudera4u --admin-password=Cloudera4u --hostname=ipa1.luqimin.cn --ip-address=172.17.2.51 --idstart=5000 --idmax=15000 --mkhomedir --setup-dns --no-forwarders --no-reverse --no-ntp
```
4. 