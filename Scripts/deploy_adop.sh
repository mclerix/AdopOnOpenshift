#!/bin/bash
#####################################################
#
# Deployment of ADOP on OpenShift
#
# Made by: Maxime CLERIX
# Date: 04/04/17
#
#####################################################
# Notes:

# PREREQUISITES:
# /
# HOW TO RUN THE SCRIPT:
# This script should be executed as root directly on the Openshift Master machine.
# su - deploy_adop.sh.sh
#
# TODO:
# Add parameters to templates
#

############ VARIABLES ############
# OpenShift Project
PROJECT_NAME=$1
PROJECT_DISPLAY_NAME="$2 ($PROJECT_NAME)"
PROJECT_DESCRIPTION="$3"

SUB_DOMAIN=$4
DEPLOYMENT_CHECK_INTERVAL=10 # Time in seconds between each check
DEPLOYMENT_CHECK_TIMES=60
###################################
function wait_for_application_deployment() {

    DC_NAME=$1 # the name of the deploymentConfig, transmitted as 1st parameter
    DEPLOYMENT_VERSION=
    RC_NAME=
    COUNTER=0

    # Validate Deployment is Active
    while [ ${COUNTER} -lt $DEPLOYMENT_CHECK_TIMES ]
    do

        DEPLOYMENT_VERSION=$(oc get -n ${PROJECT_NAME} dc ${DC_NAME} --template='{{ .status.latestVersion }}')

        RC_NAME="${DC_NAME}-${DEPLOYMENT_VERSION}"

        if [ "${DEPLOYMENT_VERSION}" == "1" ]; then
          break
        fi

        if [ $COUNTER -lt $DEPLOYMENT_CHECK_TIMES ]; then
            COUNTER=$(( $COUNTER + 1 ))
        fi

        if [ $COUNTER -eq $DEPLOYMENT_CHECK_TIMES ]; then
          echo "Max Validation Attempts Exceeded. Failed Verifying Application Deployment..."
          exit 1
        fi
        sleep $DEPLOYMENT_CHECK_INTERVAL

     done

     COUNTER=0

     # Validate Deployment Complete
     while [ ${COUNTER} -lt $DEPLOYMENT_CHECK_TIMES ]
     do

         DEPLOYMENT_STATUS=$(oc get -n ${PROJECT_NAME} rc/${RC_NAME} --template '{{ index .metadata.annotations "openshift.io/deployment.phase" }}')

         if [ ${DEPLOYMENT_STATUS} == "Complete" ]; then
           break
         elif [ ${DEPLOYMENT_STATUS} == "Failed" ]; then
             echo "Deployment Failed!"
             exit 1
         fi

         if [ $COUNTER -lt $DEPLOYMENT_CHECK_TIMES ]; then
             COUNTER=$(( $COUNTER + 1 ))
         fi


         if [ $COUNTER -eq $DEPLOYMENT_CHECK_TIMES ]; then
           echo "Max Validation Attempts Exceeded. Failed Verifying Application Deployment..."
           exit 1
         fi

         sleep $DEPLOYMENT_CHECK_INTERVAL

      done

}

function do_init_OCP_for_ADOP () {
  oc login -u system:admin
  oc new-project $PROJECT_NAME --display-name="$PROJECT_DISPLAY_NAME" --description="$PROJECT_DESCRIPTION"
  echo
  echo "$PROJECT_NAME Project created."
  echo

  echo "SETUP rights for the project: $PROJECT_NAME"
  oadm policy add-scc-to-group anyuid system:serviceaccounts:$PROJECT_NAME
  oadm policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:adop -n $PROJECT_NAME

  echo "Retrieve ADOP Templates"
  git clone https://github.com/clerixmaxime/AdopOnOpenshift.git
  cd ./AdopOnOpenshift

  echo "Create ADOP Templates for OpenShift"
  oc create -f ephemeral_templates/

  do_deploy_databases
}

function do_deploy_databases () {
  # Create Directory in /exports for persistent volumes
  echo "####################"
  echo "# DEPLOY DATABASES #"
  echo "####################"
  echo
  echo "####################"
  echo "#   GERRIT MYSQL   #"
  echo "####################"
  oc new-app mysql-ephemeral \
    -p MYSQL_PASSWORD=gerrit \
    -p MYSQL_DATABASE=gerrit \
    -p MYSQL_USER=gerrit \
    -p MYSQL_ROOT_PASSWORD=gerrit \
    -p MYSQL_VERSION=5.6 \
    -p DATABASE_SERVICE_NAME=gerrit-mysql \
    -n $PROJECT_NAME

  echo "####################"
  echo "#    SONAR MYSQL   #"
  echo "####################"
  oc new-app mysql-ephemeral \
    -p MYSQL_PASSWORD=sonar \
    -p MYSQL_DATABASE=sonar \
    -p MYSQL_USER=sonar \
    -p MYSQL_ROOT_PASSWORD=sonar \
    -p MYSQL_VERSION=5.6 \
    -p DATABASE_SERVICE_NAME=sonar-mysql \
    -n $PROJECT_NAME

  do_ldap
}

function do_ldap() {
  echo "####################"
  echo "#    DEPLOY LDAP   #"
  echo "####################"

  oc new-app adop-ldap -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_gerrit
}

function do_gerrit() {
  echo "####################"
  echo "#   DEPLOY GERRIT  #"
  echo "####################"

  echo
  echo "Waiting for gerrit-mysql and ldap deployments"
  echo
  wait_for_application_deployment "gerrit-mysql"
  wait_for_application_deployment "ldap"

  echo
  echo "Deploying Gerrit"
  echo
  oc new-app adop-gerrit -p PROJECT=$PROJECT_NAME -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_sonar
}

function do_sonar() {
  echo "####################"
  echo "#   DEPLOY SONAR   #"
  echo "####################"

  echo
  echo "Waiting for sonar-mysql deployment"
  echo
  wait_for_application_deployment "sonar-mysql"

  echo
  echo "Deploying Sonar"
  echo
  oc new-app adop-sonar -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_jenkins
}

function do_jenkins() {
  echo "####################"
  echo "#  DEPLOY JENKINS  #"
  echo "####################"

  echo
  echo "Waiting for gerrit deployment"
  echo
  wait_for_application_deployment "gerrit"

  echo
  echo "Deploying Jenkins"
  echo
  oc new-app adop-jenkins -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_nexus
}

function do_nexus() {
  echo "####################"
  echo "#   DEPLOY NEXUS   #"
  echo "####################"

  oc new-app adop-nexus -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_selenium
}

function do_selenium() {
  echo "####################"
  echo "# DEPLOY SELENIUM  #"
  echo "####################"

  oc new-app adop-selenium -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_proxy
}

function do_proxy() {
  echo "####################"
  echo "#   DEPLOY PROXY   #"
  echo "####################"

  oc new-app adop-proxy -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  do_sensu
}

function do_sensu() {
  echo "####################"
  echo "#   DEPLOY SENSU   #"
  echo "####################"

  oc new-app adop-sensu -p SUB_DOMAIN=$SUB_DOMAIN -n $PROJECT_NAME

  echo
  echo "Test sensu-redis and sensu-rabbitmq deployment"
  echo
  wait_for_application_deployment "sensu-rabbitmq"
  wait_for_application_deployment "sensu-redis"
  wait_for_application_deployment "sensu-api"
  echo
  echo "sensu-redis and sensu-rabbitmq deployed"
  echo

  echo
  echo "fix Sensu-api permissions and restart container"
  echo
  SENSU_API_POD=$(oc get pods | grep sensu-api | cut -d' ' -f 1)
  oc exec $SENSU_API_POD -c sensu-api -- chmod -R 777 /tmp/sensu_api_loaded_files
  oc exec $SENSU_API_POD  -c sensu-api -- service sensu-api restart
  echo
  echo "Sensu-api permissions fixed"
  echo

  echo
  echo "Wait for sensu-api deployment"
  echo
  wait_for_application_deployment "sensu-api"
  wait_for_application_deployment "sensu-server"
  echo
  echo "sensu-api redeployed"
  echo

  echo
  echo "fix Sensu-server permissions and restart container"
  echo
  SENSU_SERVER_POD=$(oc get pods | grep sensu-server | cut -d' ' -f 1)
  oc exec $SENSU_SERVER_POD -c sensu-server -- chmod -R 777 /tmp/sensu_server_loaded_files
  oc exec $SENSU_SERVER_POD  -c sensu-server -- service sensu-server restart
  echo
  echo "Sensu-server permissions fixed"
  echo

  echo
  echo "Wait for sensu-server deployment"
  echo
  wait_for_application_deployment "sensu-server"
  wait_for_application_deployment "sensu-client"
  echo
  echo "sensu-server redeployed"
  echo

  echo
  echo "fix Sensu-client permissions and restart container"
  echo
  SENSU_CLIENT_POD=$(oc get pods | grep sensu-client | cut -d' ' -f 1)
  oc exec $SENSU_CLIENT_POD -c sensu-client -- chmod -R 777 /tmp/sensu_client_loaded_files
  oc exec $SENSU_CLIENT_POD  -c sensu-client -- service sensu-client restart
  echo
  echo "Sensu-client permissions fixed"
  echo

  do_fix_phpldapadmin
}

# This function is a temporary fix to give access to the ldap container from ldap-phpadmin
function do_fix_phpldapadmin() {
  echo "####################"
  echo "#  Fix LDAP-Admin  #"
  echo "####################"

  LDAP_POD=$(oc get pods | grep ^ldap-[0-9]-* | cut -d' ' -f 1)
  LDAP_POD_IP=$(oc describe pod $LDAP_POD | grep IP | cut -d':' -f 2 | sed -e 's/^[ \t]*//')
  LDAP_PHP_POD=$(oc get pods | grep ^ldap-phpadmin-[0-9]-* | cut -d' ' -f 1)
  oc exec $LDAP_PHP_POD -c ldap-phpadmin -- sed -i "7s/.*/\$servers->setValue('server','host','$LDAP_POD_IP');/" /etc/phpldapadmin/config.php

  do_test_ADOP_deployment
}

function do_test_ADOP_deployment() {
  echo "########################"
  echo "# TEST ADOP DEPLOYMENT #"
  echo "########################"

  echo
  echo "Test gerrit deployment"
  echo
  wait_for_application_deployment "gerrit"
  echo
  echo "Gerrit deployed"
  echo

  echo
  echo "Test Sonar deployment"
  echo
  wait_for_application_deployment "sonar"
  echo
  echo "Sonar deployed"
  echo

  echo
  echo "Test Jenkins deployment"
  echo
  wait_for_application_deployment "jenkins"
  wait_for_application_deployment "jenkins-slave"
  echo
  echo "Jenkins deployed"
  echo

  echo
  echo "Test Nexus deployment"
  echo
  wait_for_application_deployment "nexus"
  echo
  echo "Nexus deployed"
  echo

  echo
  echo "Test Selenium deployment"
  echo
  wait_for_application_deployment "selenium-hub"
  wait_for_application_deployment "selenium-node-chrome"
  wait_for_application_deployment "selenium-node-firefox"
  echo
  echo "Selenium deployed"
  echo

  echo
  echo "Test Proxy deployment"
  echo
  wait_for_application_deployment "proxy"
  echo
  echo "Proxy deployed"
  echo

  echo "##########################"
  echo "# ADOP HAS BEEN DEPLOYED #"
  echo "##########################"

  do_init_adop_environments
}

function do_init_adop_environments() {
  oc new-project $PROJECT_NAME-dev --display-name="$PROJECT_NAME - Dev"
  oc new-project $PROJECT_NAME-test --display-name="$PROJECT_NAME - Test"
  oc new-project $PROJECT_NAME-prod --display-name="$PROJECT_NAME - Prod"

  # Allow Jenkins to deploy to apps environments.
  oadm policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME-dev -n $PROJECT_NAME-dev
  oadm policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME-test -n $PROJECT_NAME-test
  oadm policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME-prod -n $PROJECT_NAME-prod

  oadm policy add-role-to-group system:image-puller system:serviceaccounts:$PROJECT_NAME-test -n $PROJECT_NAME-dev
  oadm policy add-role-to-group system:image-puller system:serviceaccounts:$PROJECT_NAME-prod -n $PROJECT_NAME-dev

  curl -X POST http://adop:adop@jenkins-$PROJECT_NAME.$SUB_DOMAIN/jenkins/job/Load_Platform/build \
    --data-urlencode json='{"parameter": [{"name":"GIT_URL", "value":"https://github.com/sbstnbr/adop-platform-management"}, {"name":"GENERATE_EXAMPLE_WORKSPACE", "value":"true"}]}'
}

# Test if oc CLI is available
if hash oc 2>/dev/null; then
  do_init_OCP_for_ADOP
else
  echo "the OC CLI is not available on your system. Please install OC to run this script."
  exit 1
fi
