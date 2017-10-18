#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
# configuration: where to send the messages, by default, it is to router-a
APPLICATION_STATUS_TARGET=${1:-router-a} 

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT?"missing configuration for OPENSHIFT_PROJECT"}
: ${OPENSHIFT_USER?"missing configuration for OPENSHIFT_USER"}
: ${OPENSHIFT_PASSWORD?"missing configuration for OPENSHIFT_PASSWORD"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
: ${APPLICATION_STATUS_TARGET?"missing coniguration for the APPLICATION_STATUS_TARGET"}
echo "OK"

echo "Check the status of ${APPLICATION_STATUS_TARGET}"

echo "	--> make sure we are logged in"
oc whoami -c | grep ${OPENSHIFT_MASTER} | grep ${OPENSHIFT_USER} || oc login ${OPENSHIFT_MASTER} -u ${OPENSHIFT_USER} -p ${OPENSHIFT_PASSWORD} || { echo "FAILED: could login" && exit 1 ; }

echo "	--> create a project for ${APPLICATION_NAME}"
oc project ${OPENSHIFT_PROJECT} || oc new-project ${OPENSHIFT_PROJECT} ${OPENSHIFT_PROJECT_DESCRIPTION:+"--description"} $('OPENSHIFT_PROJECT_DESCRIPTION') ${OPENSHIFT_PROJECT_DISPLAY_NAME:+"--display-name"} ${OPENSHIFT_PROJECT_DISPLAY_NAME} || { echo "FAILED: could not create project" && exit 1 ; }

echo "	--> running status check against target ${APPLICATION_STATUS_TARGET}"
APPLICATION_STATUS_TARGET_POD=`oc get pods | grep ${APPLICATION_STATUS_TARGET} | awk '{printf $1;}'`
: ${APPLICATION_STATUS_TARGET_POD?"Could not find the target pod"}

{ oc get po/${APPLICATION_STATUS_TARGET_POD} || { echo "FAILED: sender target does not exist -- please run full setup to configure basic demo environment" && exit 1 ; } ; } && oc exec ${APPLICATION_STATUS_TARGET_POD} -- qdstat -b ${APPLICATION_STATUS_TARGET}.${OPENSHIFT_PROJECT}.svc.cluster.local:6000 -va || { echo "FAILED: could not send messages" && exit 1 ; }


echo "Done."