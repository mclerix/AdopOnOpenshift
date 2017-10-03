# Accenture DevOps Platform on OpenShift Container Platform

This repository aims to deploy [Accenture DevOps Platform](https://accenture.github.io/adop-docker-compose/) in an automated way on OpenShift Container Platform.

**/!\ Not production-ready.**

# Prerequisites

* Have an OpenShift instance running. This could be:
  * OpenShift Container Platform
  * OpenShift Origin
  * Minishift
* Git
* Cloudforms (Optional)
* Ansible Tower (Optional)

Want to run everything on Microsoft Azure? Have a look at [this repository](http://www.github.com/lbroudoux/openshift-azure) for a set of ARM templates on different OpenShift versions.

# How to deploy ADOP on OpenShift

1. Log in as system:admin on your OpenShift Cluster<br>
``oc login -u system:admin``
2. Download script `deploy_adop.sh` under /scripts
3. Execute `deploy_adop.sh` with parameters according your environment<br>
```bash
./deploy_adop.sh PROJECT_NAME PROJECT_DISPLAY_NAME PROJECT_DESCRIPTION SUB_DOMAIN
Example:
./deploy_adop.sh "demo" "Adop for demo" "Accenture DevOps Platform for demo" "cloudapps.example.com"
```
  - There are four parameters for this script: <br>
    PROJECT_NAME <br>
    PROJECT_DISPLAY_NAME <br>
    PROJECT_DESCRIPTION <br>
    SUB_DOMAIN (This parameter should match the wildcard of your router)

After few minutes, ADOP should be up & running on your Openshift cluster.

# Play a multi-product demo

This automated deployment of ADOP is part of a Red Hat multi-product demo involving Red Hat Ansible Tower and Red Hat CloudForms. For more information see [Ansible Tower Configuration](./ansible/README.md) and [CloudForms Configuration](./cloudforms/README.md)