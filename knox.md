### HDFS 
-  hdfs-site.xml
```
<property>
    <name>dfs.webhdfs.enabled</name>
    <value>true</value>
</property>
<property>
    <name>dfs.namenode.rpc-address</name>
    <value>sandbox.hortonworks.com:8020</value>
</property>
<property>
    <name>dfs.namenode.http-address</name>
    <value>sandbox.hortonworks.com:50070</value>
</property>
<property>
    <name>dfs.https.namenode.https-address</name>
    <value>sandbox.hortonworks.com:50470</value>
</property>

```
- REST API  
Gateway:	`https://{gateway-host}:{gateway-port}/gateway/default/webhdfs`  
Cluster:    `http://{webhdfs-host}:50070/webhdfs`  

- WEB UI  
Gateway:	`https://{gateway-host}:{gateway-port}/gateway/default/hdfs`  
Cluster:	`http://{webhdfs-host}:50070/`  


### YARN

- mapred-site.xml
```
<property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>sandbox.hortonworks.com:19888</value>
</property>
<property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>sandbox.hortonworks.com:8088</value>
</property>
```
- REST API  
Gateway:	`https://{gateway-host}:8443/gateway/default/resourcemanager`  
Cluster:	`http://{yarn-host}:8088/ws}`  

- WEB UI  
Gateway:	`https://{gateway-host}:8443/gateway/default/yarn`  
Cluster:	`http://{resource-manager-host}:8088/cluster`  
Gateway:	`https://{gateway-host}:8443/gateway/default/jobhistory`  
Cluster:	`http://{jobhistory-host}:19888/jobhistory`  


### Hive
- hive-site.xml
```
<property>
    <name>hive.server2.thrift.http.port</name>
    <value>10001</value>
    <description>Port number when in HTTP mode.</description>
</property>
<property>
    <name>hive.server2.thrift.http.path</name>
    <value>cliservice</value>
    <description>Path component of URL endpoint when in HTTP mode.</description>
</property>
<property>
    <name>hive.server2.transport.mode</name>
    <value>http</value>
    <description>Server transport mode. "binary" or "http".</description>
</property>
<property>
    <name>hive.server2.allow.user.substitution</name>
    <value>true</value>
</property>
```
Gateway:	`jdbc:hive2://{gateway-host}:8443/;ssl=true;sslTrustStore=/var/lib/knox/data-3.0.1.0-187/security/keystores/gateway.jks;trustStorePassword=knox;transportMode=http;httpPath=gateway/default/hive`  
Cluster:	`http://{hive-host}:10001/cliservice`  


### HBase/Phoenix
- HBase   
    - hbase-site.xml
```
<property>
    <name>hbase.master.info.bindAddress</name>
    <value>0.0.0.0</value>
</property>
<property>
    <name>hbase.master.info.port</name>
    <value>16010</value>
</property>
```

启动 HBase rest 服务：
```
$ /usr/hdp/current/hbase-master/bin/hbase-daemon.sh start rest -p 60080
```

-  REST API  
Gateway:	`https://{gateway-host}:8443/gateway/default/hbase`  
Cluster:	`http://{hbase-rest-host}:60080/`  

- WEB UI  
Gateway:	`https://{gateway-host}:8443/gateway/default/hbase/webui/`  
Cluster:	`http://{hbase-master-host}:16010/`  

- Phoenix
```
import java.sql.*;
import java.util.Properties;

public class Main {
    public static void main (String[] args) throws ClassNotFoundException, SQLException {
        String url = "jdbc:avatica:remote:url=https://sandbox-hdp.hortonworks.com:8443/gateway/default/avatica";
        Properties props = new Properties();
        props.setProperty("avatica_user", "admin");
        props.setProperty("avatica_password", "admin-password");
        props.setProperty("authentication", "BASIC");
        props.setProperty("serialization", "PROTOBUF");
        props.setProperty("truststore", "/var/lib/knox/data-3.0.1.0-187/security/keystores/gateway.jks");
        props.setProperty("truststore_password", "knox");
        Connection conn = DriverManager.getConnection(url, props);

        String sql = "select * from SYSTEM.CATALOG";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(sql);

        String COLUMN_NAME;
        System.out.println("-----------");
        while(rs.next()) {
            COLUMN_NAME = rs.getString("COLUMN_NAME");
            System.out.println(COLUMN_NAME);
        }
    }
}

```
```
$ javac Main.java
$ java -cp /usr/hdp/ current/phoenix-client /phoenix-thin-client.jar:. Main
```
Gateway:  `jdbc:avatica:remote:url=https://knox_gateway.domain:8443/gateway/sandbox/avatica;avatica_user=username;avatica_password=password;authentication=BASIC;truststore=/tmp/knox_truststore.jks;truststore_password=very_secret;serialization=PROTOBUF`  


### Spark/Livy

- Spark UI  
Gateway:	`https://{gateway-host}:8443/gateway/default/sparkhistory`  
Cluster:	`http://{spark-history-host}:18081`  

- Livy Session

Gateway:    `https://{gateway-host}:8443/gateway/default/livy/v1/batches`  
Cluster:    `http://{livy-host}:8999/batches`  

```
$ curl -H "Content-Type: application/json" -d '{"kind": "spark"}' -X POST http://{livy-host}:8999/sessions
$ curl -X GET http://{livy-host}:8999/sessions/0/state
$ curl -X GET http://{livy-host}:8999/sessions/0/log
$ curl -X DELETE http://{livy-host}:8999/sessions/0
$ curl -H "Content-Type: application/json" -d '{"code":"1+1"}' -X POST http://{livy-host}:8999/sessions/0/statements
$ curl -X GET http://{livy-host}:8999/sessions/0/statements/1
$ curl -H "Content-Type: application/json" -X POST http://{livy-host}:8999/sessions/0/statements/1/cancel

```

- Livy Batch
```
$ curl -H "Content-Type: application/json" -d '{ "file":"/tmp/spark-examples_2.11-2.3.1.3.0.1.0-187.jar", "className":"org.apache.spark.examples.SparkPi"}' -X POST  http://{livy-host}:8999/batches
$ curl -X GET http://{livy-host}:8999/batches/6/state
$ curl -X GET http://{livy-host}:8999/batches/6/log
$ curl -X DELETE http://{livy-host}:8999/batches/6

```

### Kakfa

Gateway:	`https://{gateway-host}:8443/gateway/default/kafka`  
Cluster:	`http://{kakfa-rest-host}:{kafka-rest-port}}`  

```
# 0. Getting topic info

curl -ikv -u guest:guest-password -X GET 'https://localhost:8443/gateway/sandbox/kafka/topics'

# 1. Publish message to topic

curl -ikv -u guest:guest-password -X POST 'https://localhost:8443/gateway/sandbox/kafka/topics/TOPIC1' -H 'Content-Type: application/vnd.kafka.json.v2+json' -H 'Accept: application/vnd.kafka.v2+json' --data '"records":[{"value":{"foo":"bar"}}]}'
```

### Oozie

Gateway:    `https://{gateway-host}:8443/gateway/default/oozie`  
Cluster:	`http://{oozie-host}:11000/oozie`



### Knox
- deployments/default.xml
```
<provider>
     <role>ha</role>
     <name>HaProvider</name>
     <enabled>true</enabled>
     <param>
         <name>WEBHCAT</name>
         <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
     </param>
     <param>
         <name>WEBHDFS</name>
         <value>maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=3;retrySleep=1000;enabled=true</value>
     </param>

    <param>
         <name>YARN</name>
         <value>maxFailoverAttempts=5;failoverSleep=5000;maxRetryAttempts=3;retrySleep=1000;enabled=auto</value>
     </param>

     <param>
         <name>OOZIE</name>
         <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
     </param>

#    <param>
#         <name>HIVE</name>
#         <value>maxFailoverAttempts=10;failoverSleep=1000;maxRetryAttempts=5;retrySleep=1000;enabled=auto</value>
#     </param>
    <param>
        <name>HIVE</name>
        <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true;zookeeperEnsemble=machine1:2181,machine2:2181,machine3:2181;zookeeperNamespace=hiveserver2</value>
    </param>

     <param>
         <name>HBASE</name>
         <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true</value>
     </param>
     <param>
        <name>WEBHBASE</name>
        <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true;zookeeperEnsemble=machine1:2181,machine2:2181,machine3:2181</value>
   </param>

   <param>
        <name>KAFKA</name>
        <value>maxFailoverAttempts=3;failoverSleep=1000;enabled=true;zookeeperEnsemble=machine1:2181,machine2:2181,machine3:2181</value>
   </param>

</provider>



<service>
    <role>NAMENODE</role>
    <url>hdfs://sandbox-hdp:8020</url>
</service>
<service>
    <role>WEBHDFS</role>
    <url>http://sandbox-hdp:50070/webhdfs</url>
</service>
<service>
    <role>HDFSUI</role>
    <url>http://sandbox.hortonworks.com:50070</url>
    <version>2.7.0</version>
</service>

<service>
    <role>RESOURCEMANAGER</role>
    <url>http://sandbox-hdp:8088/ws</url>
</service>
<service>
    <role>JOBHISTORYUI</role>
    <url>http://sandbox.hortonworks.com:19888</url>
</service>
<service>
    <role>YARNUI</role>
    <url>http://sandbox.hortonworks.com:8088</url>
</service>

#<service>
#    <role>HIVE</role>
#    <url>http://sandbox-hdp:10001/cliservice</url>
#    <param>
#        <name>replayBufferSize</name>
#        <value>8</value>
#    </param>
#</service>
<service>
    <role>HIVE</role>
</service>

<service>
  <role>AVATICA</role>
  <url>http://sandbox-hdp:8765</url>
</service>
<service>
    <role>WEBHBASE</role>
    <url>http://sandbox-hdp:60080</url>
    <param>
        <name>replayBufferSize</name>
        <value>8</value>
    </param>
</service>
<service>
    <role>HBASEUI</role>
    <url>http://sandbox.hortonworks.com:16010</url>
</service>

<service>
  <role>LIVYSERVER</role>
  <url>http://sandbox-hdp:8999</url>
</service>
<service>
    <role>SPARKHISTORYUI</role>
    <url>http://sandbox.hortonworks.com:18081/</url>
</service>

#<service>
#    <role>KAFKA</role>
#    <url>http://sandbox-hdp:<kafka-rest-port></url>
#</service>
<service>
    <role>KAFKA</role>
</service>


<service>
    <role>JOBTRACKER</role>
    <url>rpc://sandbox-hdp:8050</url>
</service>
<service>
    <role>OOZIE</role>
    <url>http://sandbox-hdp:11000/oozie</url>
    <param>
        <name>replayBufferSize</name>
        <value>8</value>
    </param>
</service>
<service>
    <role>OOZIEUI</role>
    <url>http://sandbox.hortonworks.com:11000/oozie</url>
</service>

```


