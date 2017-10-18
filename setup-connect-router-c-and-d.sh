#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
# NONE

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT?"missing configuration for OPENSHIFT_PROJECT"}
: ${OPENSHIFT_USER?"missing configuration for OPENSHIFT_USER"}
: ${OPENSHIFT_PASSWORD?"missing configuration for OPENSHIFT_PASSWORD"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Create the resilient network demo"

echo "	--> make sure we are logged in"
oc whoami -c | grep ${OPENSHIFT_MASTER} | grep ${OPENSHIFT_USER} || oc login ${OPENSHIFT_MASTER} -u ${OPENSHIFT_USER} -p ${OPENSHIFT_PASSWORD} || { echo "FAILED: could login" && exit 1 ; }

echo "	--> create a project for ${APPLICATION_NAME}"
oc project ${OPENSHIFT_PROJECT} || { echo "FAILED: project does not exist -- please run full setup to configure basic demo environment" && exit 1 ; }

oc get dc/router-c && oc set env dc/router-c QDROUTER_CONF=/etc/qpid-dispatch/router-c-mod.conf

echo "Done."