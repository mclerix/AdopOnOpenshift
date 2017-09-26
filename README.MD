# Prerequisites

* Have an OpenShift instance running. This could be :
  * OpenShift Container Platform
  * OpenShift Origin
  * Minishift
* Git installed

Want to run everything on Microsoft Azure? Have a look at [this repository](http://www.github.com/lbroudoux/openshift-azure) for a set of ARM templates on different OpenShift versions.

# How to run Adop on OpenShift

Adop is a large solution with a lot components, so, before going on the installation of Adop on OpenShift, you should download Adop images on your OpenShift cluster. For that purpose, you can use the ``adop_warmup.sh`` script on all your OpenShift nodes.
## Manually
To run ADOP on Openshift, you should do the following steps.

1. Log in as system:admin on your openshift ClusterFirst <br>
``oc login -u system:admin``
2. Create a project called "adop" <br>
``oc new-project adop``<br>
3. Set up roles and scc for serviceaccounts in project "adop" to allow them to deploy ADOP containers without authorization issues. <br>
``oadm policy add-scc-to-group anyuid system:serviceaccounts:adop``<br>
``oadm policy add-role-to-user edit system:serviceaccount:adop:adop``
4. Clone git repository <br>
``git clone https://github.com/clerixmaxime/AdopOnOpenshift.git``
5. Move to directory <br>
``cd ./AdopOnOpenshift``
6. Populate Openshift with ADOP Templates <br>
``oc create -f templates/``
7. Deploy templates

```bash
# Create MYSQL databases for Gerrit and Sonar using template provided by OpenShift (Could be replaced by persistent template).
oc new-app mysql-ephemeral -p MYSQL_PASSWORD=gerrit -p MYSQL_DATABASE=gerrit -p MYSQL_USER=gerrit -p MYSQL_ROOT_PASSWORD=gerrit -p MYSQL_VERSION=5.6 -p DATABASE_SERVICE_NAME=gerrit-mysql -n adop

oc new-app mysql-ephemeral -p MYSQL_PASSWORD=sonar -p MYSQL_DATABASE=sonar -p MYSQL_USER=sonar -p MYSQL_ROOT_PASSWORD=sonar -p MYSQL_VERSION=5.6 -p DATABASE_SERVICE_NAME=sonar-mysql -n adop

oc new-app adop-ldap
oc new-app adop-gerrit
oc new-app adop-sensu
oc new-app adop-sonar
oc new-app adop-jenkins
oc new-app adop-nexus
oc new-app adop-selenium
oc new-app adop-proxy
```
*/!\ you should wait for adop-gerrit deployment completion before launching Jenkins*

## Automatically via a script

1. Log in as system:admin on your OpenShift Cluster<br>
``oc login -u system:admin``
2. Download script `deploy_adop.sh` under /scripts
3. Execute `deploy_adop.sh` with parameters according your environment<br>
```bash
./deploy_adop.sh PROJECT_NAME PROJECT_DISPLAY_NAME PROJECT_DESCRIPTION SUB_DOMAIN
Example:
./deploy_adop.sh adop "Adop project" "Deployment of ADOP by Accenture" apps.example.com
```
  - There are four parameters for this script: <br>
    PROJECT_NAME <br>
    PROJECT_DISPLAY_NAME <br>
    PROJECT_DESCRIPTION <br>
    SUB_DOMAIN (This parameter should match the wildcard of your cluster)

After that, the ADOP stack should be deployed and available in your Openshift cluster.

# TODO

* Add ELK stack or synchronize with openshift-metrics.
* Add persistent volumes for required containers (cf. https://github.com/Accenture/adop-docker-compose/blob/master/etc/volumes/nfs/default.yml for volumes list).
* Fix Sensu deployment
* Write parameters' description.
