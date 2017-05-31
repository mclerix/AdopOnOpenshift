#!/bin/bash
# Run the script once for intializing your newly Openshift cluster with required image for AskMe
oc new-build https://github.com/clerixmaxime/sti-grunt-nginx.git --context-dir=/1.0 --strategy=docker --to=sti-grunt-nginx -n openshift
