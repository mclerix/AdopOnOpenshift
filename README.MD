# Prerequisites

* Have an OpenShift instance running. This could be :
  * OpenShift Container Platform
  * OpenShift Origin
  * Minishift
* Git installed
* Make sure you have at least 30 Gi available in your docker devicemapper for ADOP images

# How to run ADOP on OpenShift

To run ADOP on Openshift, you should do the following steps.

1. Log in as system:admin on your openshift ClusterFirst <br>
``oc login -u system:admin``
2. Create a project called "adop" <br>
``oc new-project adop``<br>
*You should be redirected in the project adop, if it is not the case make sure you are in adop project by typing ``oc project adop``*
3. Set up rights for serviceaccounts in project "adop" to allow them to deploy ADOP containers without permissions issues. <br>
``oadm policy add-scc-to-group anyuid system:serviceaccounts:adop``<br>
``oadm policy add-role-to-user edit system:serviceaccount:adop:adop``
4. Clone git repository <br>
``git clone https://github.com/clerixmaxime/AdopOnOpenshift.git``
5. Move to directory <br>
``cd ./AdopOnOpenshift``
6. Populate Openshift with ADOP Templates <br>
``oc create -f Templates/``
7. Deploy templates
```
oc new-app adop-ldap
oc new-app adop-gerrit
oc new-app adop-sensu
oc new-app adop-sonar
oc new-app adop-jenkins
oc new-app adop-nexus
oc new-app adop-selenium
oc new-app adop-proxy
```
*The templates are also available in the OpenShift Catalog and can be found with a search (ex: adop)*

After that, the ADOP stack should be deployed and available in your Openshift cluster with the errors identified below.

# Errors identified

**/!\ an ELK stack is required by ADOP.**

## Proxy
Nginx does not start and requires all the other Components URL up. Moreover it requires the ELK stack. <br>
```
waiting for kibana:5601 to be available
kibana:5601 unavailable, sleeping for 2
kibana:5601 unavailable, sleeping for 2
...
```
> related to the pull request: https://github.com/janwillies/adop-docker-compose/blob/kubernetes-support. A new image has been designed to run the proxy (willies/adop-nginx).

## LDAP
### ldap
WORKS
### ldap-phpadmin
ldap-phpadmin can't connect directly to ldap server using hostname. However, reconfiguring ``/etc/phpldapadmin/config.php`` and set the IP address of the ldap-server container instead of its hostname seems to fix the problem. See example below: <br>

```php
<?php
$servers = new Datastore();
$servers->newServer('ldap_pla');
$servers->setValue('server','name','ldap');
$servers->setValue('server','__IP_ADDRESS__','ldap');
$servers->setValue('server','port','389');
$servers->setValue('server','base',array('dc=ldap,dc=example,dc=com'));
$servers->setValue('login','auth_type','cookie');
$servers->setValue('login','bind_id','cn=admin,dc=ldap,dc=example,dc=com');
$servers->setValue('server','tls',false);
?>
```

### ldap-ltb
WEB UI is up.
Logs display the following message: <br>
```
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 10.128.0.42. Set the 'ServerName' directive globally to suppress this message
```

## Gerrit
### gerrit-mysql
WORKS
### gerrit
**CRITICAL** Once launched, Gerrit display the following message each 10 seconds: <br>
`Gerrit unavailable, sleeping for 10` <br>
Content of ``gc_log`` file: <br>
`2017-03-22 13:53:29,570] INFO  : Ignoring missing gc schedule configuration` <br>
`httpd_log` & `sshd_log` do not display any errors <br>
> It seems that $GERRIT_HOME/adop_scripts/create_user.sh tries to curl an address that does not exist and can't create users even if Gerrit is up and running.

## Sensu
### sensu-redis
WORKS
### sensu-rabbitmq
WORKS
### sensu-api
/!\ Requires to be launched once rabbitmq is ready to avoid the following error:
```bash
{"timestamp":"2017-03-23T08:51:58.830830+0000","level":"error","message":"redis connection error","error":"unable to connect to redis server"}
{"timestamp":"2017-03-23T08:51:59.022461+0000","level":"error","message":"[amqp] Detected TCP connection failure: Errno::EHOSTUNREACH"}
```

**CRITICAL** Once launched, sensu does not start and issue the following error:
```
# cat sensu-api.log
/opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `initialize': Permission denied @ rb_sysopen - /tmp/sensu_api_loaded_files (Errno::EACCES)
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `open'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `create_loaded_tempfile!'
        from /opt/sensu/embedded/lib /ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:198:in `set_env!'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:34:in `load'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:48:in `get'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:133:in `load_settings'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:53:in `initialize'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/api/process.rb:16:in `new'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/api/process.rb:16:in `run'
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/exe/sensu-api:10:in `<top (required)>'
        from /opt/sensu/bin/sensu-api:22:in `load'
        from /opt/sensu/bin/sensu-api:22:in `<main>'                                                                                            
```

**Current fix** <br>
Once running, exec the following command:<br>
``oc exec <sensu-api-pod> -c sensu-api -- chmod -R 777 /tmp/sensu_api_loaded_files`` <br>
``oc exec <sensu-api-pod> -c sensu-api -- service sensu-api restart`` <br>
To get <sensu-server-pod>, you can type the following command: <br>
``oc get pods | grep sensu-server | cut -d' ' -f 1``

### sensu-server
/!\ Requires to be launched once rabbitmq is ready to avoid the following error:
```bash
{"timestamp":"2017-03-23T08:52:01.840097+0000","level":"error","message":"redis connection error","error":"unable to connect to redis server"}
{"timestamp":"2017-03-23T08:52:02.028845+0000","level":"error","message":"[amqp] Detected TCP connection failure: Errno::EHOSTUNREACH"}
```
**CRITICAL** Once launched, sensu does not start and issue the following error:
```
/opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `initialize': Permission denied @ rb_sysopen - /tmp/sensu_server_loaded_files (Errno::EACCES)                                    
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `open'                                                                                                              
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `create_loaded_tempfile!'                                                                                           
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:198:in `set_env!'                                                                                                          
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:34:in `load'                                                                                                                      
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:48:in `get'                                                                                                                       
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:133:in `load_settings'                                                                                                                      
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:53:in `initialize'                                                                                                                          
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/server/process.rb:42:in `initialize'                                                                                                                  
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/server/process.rb:30:in `new'                                                                                                                         
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/server/process.rb:30:in `run'                                                                                                                         
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/exe/sensu-server:10:in `<top (required)>'                                                                                                                       
        from /opt/sensu/bin/sensu-server:22:in `load'                                                                                                                                                                                  
        from /opt/sensu/bin/sensu-server:22:in `<main>'
```

**Current fix** <br>
Once running, exec the following command:<br>
``oc exec <sensu-server-pod> -c sensu-server -- chmod -R 777 /tmp/sensu_server_loaded_files`` <br>
``oc exec <sensu-server-pod> -c sensu-server -- service sensu-server restart`` <br>
To get <sensu-server-pod>, you can type the following command: <br>
``oc get pods | grep sensu-server | cut -d' ' -f 1``

### sensu-client
/!\ Requires to be launched once rabbitmq is ready to avoid the following error:
```
{"timestamp":"2017-03-23T09:24:40.169105+0000","level":"fatal","message":"SENSU NOT RUNNING!"}
```
**CRITICAL** Once launched, sensu does not start and issue the following error:
```
# cat sensu-client.log                                                                                                                                                                                                                                                      
/opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `initialize': Permission denied @ rb_sysopen - /tmp/sensu_client_loaded_files (Errno::EACCES)                                                                         
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `open'                                                                                                                                                   
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:405:in `create_loaded_tempfile!'                                                                                                                                
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings/loader.rb:198:in `set_env!'                                                                                                                                               
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:34:in `load'                                                                                                                                                           
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-settings-9.2.1/lib/sensu/settings.rb:48:in `get'                                                                                                                                                            
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:133:in `load_settings'                                                                                                                                                           
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:53:in `initialize'                                                                                                                                                               
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:29:in `initialize'                                                                                                                                                       
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:17:in `new'                                                                                                                                                              
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:17:in `run'                                                                                                                                                              
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/exe/sensu-client:10:in `<top (required)>'                                                                                                                                                            
        from /opt/sensu/bin/sensu-client:22:in `load'                                                                                                                                                                                                                       
        from /opt/sensu/bin/sensu-client:22:in `<main>'  
```

**Current fix** <br>
Once running, exec the following command:<br>
``oc exec <sensu-client-pod> -c sensu-client -- chmod -R 777 /tmp/sensu_client_loaded_files`` <br>
``oc exec <sensu-client-pod> -c sensu-client -- service sensu-client restart`` <br>
To get <sensu-client-pod>, you can type the following command: <br>
``oc get pods | grep sensu-client | cut -d' ' -f 1``


The following error occurs after trying to relaunch sensu-client service:

```

/opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/eventmachine.rb:530:in `start_tcp_server': no acceptor (port is in use or requires root privileges) (RuntimeError)                                               
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/eventmachine.rb:530:in `start_server'                                                                                                               
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:364:in `setup_sockets'                                                                                                              
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:452:in `block in start'                                                                                                             
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/daemon.rb:273:in `block in setup_transport'                                                                                                           
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-transport-6.0.0/lib/sensu/transport.rb:26:in `block in connect'                                                                                                        
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/em/deferrable.rb:151:in `set_deferred_status'                                                                                                       
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/em/deferrable.rb:191:in `succeed'                                                                                                                   
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-transport-6.0.0/lib/sensu/transport/rabbitmq.rb:195:in `block in setup_connection'                                                                                     
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/em/deferrable.rb:151:in `set_deferred_status'                                                                                                       
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/em/deferrable.rb:191:in `succeed'                                                                                                                   
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:682:in `connection_successful'                                                                                                                
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:1040:in `handle_open_ok'                                                                                                                      
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:1136:in `block in <class:Session>'                                                                                                            
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:959:in `receive_frameset'                                                                                                                     
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:933:in `receive_frame'                                                                                                                        
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/amqp-1.6.0/lib/amqp/session.rb:671:in `receive_data'                                                                                                                         
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/eventmachine.rb:194:in `run_machine'                                                                                                                
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/eventmachine-1.2.0.1/lib/eventmachine.rb:194:in `run'                                                                                                                        
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/lib/sensu/client/process.rb:18:in `run'                                                                                                                         
        from /opt/sensu/embedded/lib/ruby/gems/2.3.0/gems/sensu-0.26.5/exe/sensu-client:10:in `<top (required)>'                                                                                                                       
        from /opt/sensu/bin/sensu-client:22:in `load'                                                                                                                                                                                  
        from /opt/sensu/bin/sensu-client:22:in `<main>'    
```

### sensu-uchiwa
Sensu-uchiwa can't connect to sensu-api (Actually, Service is not running). However, the web interface is accessible.
```
{"timestamp":"2017-03-23T09:15:13.41385771Z","level":"warn","message":"GET http://sensu-api:4567/stashes returned: Get http://sensu-api:4567/stashes: dial tcp 172.30.201.20:4567: getsockopt: no route to host"}
{"timestamp":"2017-03-23T09:15:13.413886253Z","level":"warn","message":"Connection failed to the datacenter Sensu"}
```

## Sonar
### sonar-mysql
WORKS
### sonar
WORKS. Default user admin/admin
Currently, Sonar is the only container that is able to reach LDAP.

## Jenkins
Errors during installation:
* **CRITICAL** Can't access Gerrit
```
WARNING: Failed to run script file:/var/jenkins_home/init.groovy.d/adop_gerrit.groovy
java.lang.NumberFormatException: For input string: "tcp://172.30.75.45:29418"
	at java.lang.NumberFormatException.forInputString(NumberFormatException.java:65)
	at java.lang.Integer.parseInt(Integer.java:580)
	at java.lang.Integer.valueOf(Integer.java:766)
	at org.codehaus.groovy.runtime.DefaultGroovyMethods.toInteger(DefaultGroovyMethods.java:14035)
	at org.codehaus.groovy.runtime.dgm$821.invoke(Unknown Source)
	at org.codehaus.groovy.runtime.callsite.PojoMetaMethodSite$PojoMetaMethodSiteNoUnwrapNoCoerce.invoke(PojoMetaMethodSite.java:271)
	at org.codehaus.groovy.runtime.callsite.PojoMetaMethodSite.call(PojoMetaMethodSite.java:53)
	at org.codehaus.groovy.runtime.callsite.CallSiteArray.defaultCall(CallSiteArray.java:42)
	at org.codehaus.groovy.runtime.callsite.AbstractCallSite.call(AbstractCallSite.java:108)
	at org.codehaus.groovy.runtime.callsite.AbstractCallSite.call(AbstractCallSite.java:112)
	at adop_gerrit.run(adop_gerrit.groovy:18)
	at groovy.lang.GroovyShell.evaluate(GroovyShell.java:580)
	at jenkins.util.groovy.GroovyHookScript.execute(GroovyHookScript.java:122)
	at jenkins.util.groovy.GroovyHookScript.execute(GroovyHookScript.java:113)
	at jenkins.util.groovy.GroovyHookScript.run(GroovyHookScript.java:96)
	at hudson.init.impl.GroovyInitScript.init(GroovyInitScript.java:42)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:497)
	at hudson.init.TaskMethodFinder.invoke(TaskMethodFinder.java:106)
	at hudson.init.TaskMethodFinder$TaskImpl.run(TaskMethodFinder.java:176)
	at org.jvnet.hudson.reactor.Reactor.runTask(Reactor.java:282)
	at jenkins.model.Jenkins$7.runTask(Jenkins.java:904)
	at org.jvnet.hudson.reactor.Reactor$2.run(Reactor.java:210)
	at org.jvnet.hudson.reactor.Reactor$Node.run(Reactor.java:117)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:745)
```
* **CRITICAL** Can't access ldap
```
WARNING: Failed to run script file:/var/jenkins_home/init.groovy.d/adop_ldap.groovy
java.lang.NullPointerException: Cannot invoke method toBoolean() on null object
	at org.codehaus.groovy.runtime.NullObject.invokeMethod(NullObject.java:77)
	at org.codehaus.groovy.runtime.callsite.PogoMetaClassSite.call(PogoMetaClassSite.java:45)
	at org.codehaus.groovy.runtime.callsite.CallSiteArray.defaultCall(CallSiteArray.java:42)
	at org.codehaus.groovy.runtime.callsite.NullCallSite.call(NullCallSite.java:32)
	at org.codehaus.groovy.runtime.callsite.CallSiteArray.defaultCall(CallSiteArray.java:42)
	at org.codehaus.groovy.runtime.callsite.AbstractCallSite.call(AbstractCallSite.java:108)
	at org.codehaus.groovy.runtime.callsite.AbstractCallSite.call(AbstractCallSite.java:112)
	at adop_ldap.run(adop_ldap.groovy:27)
	at groovy.lang.GroovyShell.evaluate(GroovyShell.java:580)
	at jenkins.util.groovy.GroovyHookScript.execute(GroovyHookScript.java:122)
	at jenkins.util.groovy.GroovyHookScript.execute(GroovyHookScript.java:113)
	at jenkins.util.groovy.GroovyHookScript.run(GroovyHookScript.java:96)
	at hudson.init.impl.GroovyInitScript.init(GroovyInitScript.java:42)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:497)
	at hudson.init.TaskMethodFinder.invoke(TaskMethodFinder.java:106)
	at hudson.init.TaskMethodFinder$TaskImpl.run(TaskMethodFinder.java:176)
	at org.jvnet.hudson.reactor.Reactor.runTask(Reactor.java:282)
	at jenkins.model.Jenkins$7.runTask(Jenkins.java:904)
	at org.jvnet.hudson.reactor.Reactor$2.run(Reactor.java:210)
	at org.jvnet.hudson.reactor.Reactor$Node.run(Reactor.java:117)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:745)
```
* **CRITICAL** Installation stuck at the step Saving changes.
```
...
--> Configuring Ant
--> Configuring Maven
--> Configuring NodeJS
--> Configuring SonarQube
--> Configuring SonarRunner
--> setting agent port for jnlp
Enabling role based authorisation strategy...
Admin role created...OK
Read role created...OK
Saving changes.
```

## Selenium
Selenium-hub, selenium-node-firefox & selenium-node-chrome components WORK

## Nexus
Nexus can be deployed without errors when LDAP is disabled. When LDAP is enabled, the following error occurs:
```
1) Error injecting constructor, org.sonatype.nexus.configuration.ModelUtils$CorruptModelException: Model corruptedUnable to parse element 'port', must be an integer (position: END_TAG seen ...<port>tcp://172.30.217.255:389</port>... @11:42) caused by: java.lang.NumberFormatException: For input string: "tcp://172.30.217.255:389"
  at org.sonatype.security.ldap.realms.persist.DefaultLdapConfiguration.<init>(DefaultLdapConfiguration.java:38)
  at org.sonatype.nexus.plugins.nexus-ldap-realm-plugin [29]([file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/nexus-ldap-realm-plugin-2.11.3-01.jar, file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/dependencies/nexus-ldap-common-2.11.3-01.jar]) (via modules: org.eclipse.sisu.wire.WireModule -> org.eclipse.sisu.plexus.PlexusBindingModule)
  while locating org.sonatype.security.ldap.realms.persist.DefaultLdapConfiguration
  while locating java.lang.Object annotated with *
  at org.eclipse.sisu.wire.LocatorWiring
  while locating org.sonatype.security.ldap.realms.persist.LdapConfiguration
    for parameter 3 at org.sonatype.nexus.security.ldap.realms.DefaultLdapManager.<init>(DefaultLdapManager.java:40)
  at org.sonatype.nexus.plugins.nexus-ldap-realm-plugin [29]([file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/nexus-ldap-realm-plugin-2.11.3-01.jar, file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/dependencies/nexus-ldap-common-2.11.3-01.jar]) (via modules: org.eclipse.sisu.wire.WireModule -> org.eclipse.sisu.plexus.PlexusBindingModule)
  while locating org.sonatype.nexus.security.ldap.realms.DefaultLdapManager
  while locating java.lang.Object annotated with *
  at org.eclipse.sisu.wire.LocatorWiring
  while locating org.sonatype.security.ldap.realms.LdapManager
    for parameter 0 at org.sonatype.nexus.security.ldap.realms.NexusLdapAuthenticationRealm.<init>(NexusLdapAuthenticationRealm.java:33)
  at org.sonatype.nexus.plugins.nexus-ldap-realm-plugin [29]([file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/nexus-ldap-realm-plugin-2.11.3-01.jar, file:/opt/sonatype/nexus/nexus/WEB-INF/plugin-repository/nexus-ldap-realm-plugin-2.11.3-01/dependencies/nexus-ldap-common-2.11.3-01.jar]) (via modules: org.eclipse.sisu.wire.WireModule -> org.eclipse.sisu.plexus.PlexusBindingModule)
  while locating org.sonatype.nexus.security.ldap.realms.NexusLdapAuthenticationRealm
while locating java.lang.Object annotated with *
```
Providing the IP address of the container running LDAP as LDAP_URL does not solve the issue in this case. <br>
> related to the pull request: https://github.com/janwillies/adop-docker-compose/blob/kubernetes-support. A new image has been designed to run nexus (willies/adop-nexus).

# TODO

* Fix issues listed above.
* Add ELK stack or synchronize with openshift-metrics.
* Add persistent volumes for required containers (cf. https://github.com/Accenture/adop-docker-compose/blob/master/etc/volumes/nfs/default.yml for volumes list).
* Configure Jenkins to deploy on Openshift.
* Configure Jenkins to sync with Openshift (Should work out-of-the-box once Openshift plugins will be installed).
* Configure jenkins to deploy slave in Openshift instead of Docker. Currently, ADOP Jenkins is configured to with Docker Host information in order to deploy Jenkins Slave within Docker container on the host it is running on. Using Kubernetes plugin, jenkins could be configured to use Openshift as a deployment platform to deploy also jenkins slaves (https://blog.openshift.com/jenkins-slaves-in-openshift-using-an-external-jenkins-environment/).
* Identify Required parameters.
* Write parameters' description.
* Write Readiness and liveness probes for ADOP containers.
