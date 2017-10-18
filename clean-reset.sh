#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
# NONE


echo "Delete the resilient networking"

echo "	--> make sure we are logged in"
oc whoami || oc login master.rhsademo.net -u mepley -p ${OPENSHIFT_RHSADEMO_USER_PASSWORD_DEFAULT}
echo "	--> make sure we are using the correct project"
oc project ${OPENSHIFT_PROJECT} || { echo "WARNING: missing project -- nothing to do" && exit 0; }

echo "	--> deleting all openshift resources"
oc delete dc,svc --all
oc delete cm/network-config

echo "Done"
