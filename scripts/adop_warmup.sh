#!/bin/bash
# Run this script on all the nodes of your cluster for provisioning Adop images
docker pull clrxm/adop-gerrit:0.1.2
docker pull accenture/adop-gerrit:0.1.3
docker pull accenture/adop-ldap:0.1.3
docker pull accenture/adop-ldap-ltb:0.1.0
docker pull accenture/adop-ldap-phpadmin:0.1.0
docker pull accenture/adop-sonar:0.2.0
docker pull accenture/adop-nexus:0.1.3
docker pull selenium/hub:2.53.0
docker pull selenium/node-chrome:2.53.0
docker pull selenium/node-firefox:2.53.0
docker pull clrxm/adop-sensu:0.26.5
docker pull sstarcher/uchiwa:0.15.0
docker pull rabbitmq:3.5.7-management
docker pull redis:3.0.7
docker pull clrxm/adop-jenkins:2.7.4
docker pull accenture/adop-jenkins-slave:0.1.4
docker pull clrxm/adop-nginx:0.1.0
