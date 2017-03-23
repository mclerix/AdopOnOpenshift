#!/bin/bash
#####################################################
#
# Description:
# Made by: Maxime CLERIX
# Date: 27/02/17
#
#####################################################
# Notes:

# HOW TO RUN THE SCRIPT:
#

############ VARIABLES ############

PROJECT_NAME="adop"
PROJECT_DISPLAY_NAME="ADOP, DevOps tools by Accenture"
PROJECT_DESCRIPTION="adop"
SERVICEACCOUNT="adop"


###################################

function do_Init () {
  oc login -u system:admin
  oc new-project $PROJECT_NAME --display-name="$PROJECT_DISPLAY_NAME" --description="$PROJECT_DESCRIPTION"
  echo
  echo "$PROJECT_NAME Project created."
  echo

  echo '{
    "apiVersion": "v1",
    "kind": "ServiceAccount",
    "metadata": {
      "name": "adop"
    },
    "secrets": [
      {"name": "adop-account"}
    ]
  }' | oc create -f -

  oadm policy add-scc-to-user anyuid -z $SERVICEACCOUNT -n $PROJECT_NAME
  oadm policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:$SERVICEACCOUNT

  do_proxy
}

function do_proxy () {

  # Download proxy template from Github

  oc create -f ldap-template.yml -n openshift

  do_ldap
}

function do_LDAP () {

  # Download template from Github
  oc create -f ldap-template.yml -n openshift

  do_ldap
}


# Test if oc CLI is available
if hash oc 2>/dev/null; then
  do_Init
else
  echo "the OC CLI is not available on your system. Please install OC to run this script."
  exit 1
fi
