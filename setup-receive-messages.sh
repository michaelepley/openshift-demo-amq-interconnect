#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration

# configuration: where to recieve messages from, by default, it is to router-d
APPLICATION_RECEIVER_TARGET=${1:-router-d} 

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT?"missing configuration for OPENSHIFT_PROJECT"}
: ${OPENSHIFT_USER?"missing configuration for OPENSHIFT_USER"}
: ${OPENSHIFT_PASSWORD?"missing configuration for OPENSHIFT_PASSWORD"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
: ${APPLICATION_RECEIVER_TARGET?"missing coniguration for the APPLICATION_RECEIVER_TARGET"}
echo "OK"


echo "Sending test messages to ${APPLICATION_SENDER_TARGET}"

echo "	--> make sure we are logged in"
oc whoami -c | grep ${OPENSHIFT_MASTER} | grep ${OPENSHIFT_USER} || oc login ${OPENSHIFT_MASTER} -u ${OPENSHIFT_USER} -p ${OPENSHIFT_PASSWORD} || { echo "FAILED: could login" && exit 1 ; }

echo "	--> create a project for ${APPLICATION_NAME}"
oc project ${OPENSHIFT_PROJECT} || { echo "FAILED: project does not exist -- please run full setup to configure basic demo environment" && exit 1 ; }




echo "	--> starting up message receiver"
DOCKER_IMAGE_FQN=`oc get is/amq-interconnect --template='{{.status.dockerImageRepository}}'`
{ oc get dc/${APPLICATION_RECEIVER_TARGET} || { echo "FAILED: receiver target does not exist -- please run full setup to configure basic demo environment" && exit 1 ; } ; } && oc run  receiver --image=${DOCKER_IMAGE_FQN} --restart=Never --command -- python /usr/share/qpid-proton/examples/python/simple_recv.py -a ${APPLICATION_RECEIVER_TARGET}.${OPENSHIFT_PROJECT}.svc.cluster.local:6000/101st_Airborne_Division/506th_Parachute_Infantry_Regiment/HQ -m 5 || { echo "FAILED: could not received messages" && exit 1 ; }
echo "	--> waiting for messages to be received, press any key to cancel"
while [ ! "`oc get po/receiver --template='{{range .status.conditions}}{{if (eq .type "Initialized")}}{{.reason}}{{end}}{{end}}'`" == "PodCompleted" ] ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
oc get po/receiver && oc logs po/receiver
echo "	--> deleting receiver pod"
oc get po/receiver && oc delete po/receiver

echo "Done."