### 安装相关包
```
yum install libcgroup libcgroup-tools
systemctl start cgconfig
```
### 所有节点每次开机前执行：

```
#!/bin/bash
mkdir -p /sys/fs/cgroup/cpu/yarn
mkdir -p /sys/fs/cgroup/memory/yarn
mkdir -p /sys/fs/cgroup/blkio/yarn
mkdir -p /sys/fs/cgroup/net_cls/yarn
chown -R yarn /sys/fs/cgroup/cpu/yarn
chown -R yarn /sys/fs/cgroup/memory/yarn
chown -R yarn /sys/fs/cgroup/blkio/yarn
chown -R yarn /sys/fs/cgroup/net_cls/yarn
```

### 修改yarn-site.xml:
```
<property>
 <name>yarn.nodemanager.container-executor.class</name>
 <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
</property>

<property>
 <name>yarn.nodemanager.linux-container-executor.group</name>
 <value>hadoop</value>
</property> 

<property>
 <name>yarn.nodemanager.linux-container-executor.resources-handler.class</name>
 <value>org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler</value>
</property>

<property>
 <name>yarn.nodemanager.linux-container-executor.cgroups.hierarchy</name>
 <value>/yarn</value>
</property> 

<property>
 <name>yarn.nodemanager.linux-container-executor.cgroups.mount</name>
 <value>false</value>
</property> 

<property>
 <name>yarn.nodemanager.linux-container-executor.cgroups.mount-path</name>
 <value>/sys/fs/cgroup</value>
</property> 

<property>
 <name>yarn.nodemanager.resource.percentage-physical-cpu-limit</name>
 <value>100</value>
</property> 

<property> 
 <name>yarn.nodemanager.linux-container-executor.cgroups.strict-resource-usage</name>
 <value>true</value>
</property>
```
