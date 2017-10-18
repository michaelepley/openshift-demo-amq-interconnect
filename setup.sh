#!/bin/bash


# Configuration
. ./config.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

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

echo "	--> create configuration resources"
for ROUTERID in {a..d} ; do
	ROUTER_DNS_NAME=router-${ROUTERID}
	ROUTER_NAME=Router.${ROUTERID^^}
	ROUTER_ADDRESS=ROUTER.${ROUTERID^^}
	if [[ -f resources/prototypes/${ROUTER_DNS_NAME}.conf.prototype && ! -f resources/${ROUTER_DNS_NAME}.conf ]] ; then
		echo "	--> create configuration for ${ROUTER_DNS_NAME}"
		eval "cat <<EOF
$(<resources/prototypes/${ROUTER_DNS_NAME}.conf.prototype)
EOF
" 2> /dev/null > resources/${ROUTER_DNS_NAME}.conf
	else
		echo "	--> using existing configuration for ${ROUTER_DNS_NAME}"
	fi
	if [[ -f resources/prototypes/${ROUTER_DNS_NAME}-mod.conf.prototype && ! -f resources/${ROUTER_DNS_NAME}-mod.conf ]] ; then
		echo "	--> create modified configuration for ${ROUTER_DNS_NAME}"
		eval "cat <<EOF
$(<resources/prototypes/${ROUTER_DNS_NAME}-mod.conf.prototype)
EOF
" 2> /dev/null > resources/${ROUTER_DNS_NAME}-mod.conf
	else
		echo "	--> using existing modified configuration for ${ROUTER_DNS_NAME}"
	fi

done

echo "	--> make sure we are logged in"
oc whoami -c | grep ${OPENSHIFT_MASTER} | grep ${OPENSHIFT_USER} || oc login ${OPENSHIFT_MASTER} -u ${OPENSHIFT_USER} -p ${OPENSHIFT_PASSWORD} || { echo "FAILED: could login" && exit 1 ; }

echo "	--> create a project for ${APPLICATION_NAME}"
oc project ${OPENSHIFT_PROJECT} || oc new-project ${OPENSHIFT_PROJECT} ${OPENSHIFT_PROJECT_DESCRIPTION:+"--description"} $('OPENSHIFT_PROJECT_DESCRIPTION') ${OPENSHIFT_PROJECT_DISPLAY_NAME:+"--display-name"} ${OPENSHIFT_PROJECT_DISPLAY_NAME} || { echo "FAILED: could not create project" && exit 1 ; }

echo "	--> create the config map for the resilient network"
oc get cm/network-config || oc create configmap network-config --from-file=resources/  || { echo "FAILED: could not create the configuration map " && exit 1; }
echo "	--> create a build for the resilient network"
oc get bc/amq-interconnect || oc new-build --code=https://github.com/rlucente-se-jboss/resilient-network-demo.git --name=amq-interconnect --strategy=docker  || { echo "FAILED: could not create build" && exit 1; }
echo "	--> waiting for build to succeed, press any key to cancel"
while [ ! "`oc get build -l buildconfig=amq-interconnect --template='{{range .items}}{{if (eq .metadata.name "amq-interconnect-1")}}{{.status.phase}}{{end}}{{end}}'`" == "Complete" ] ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

echo "	--> Deploy the broker"
oc get dc/broker || oc new-app --name=broker --image-stream=jboss-amq-63
sleep 1s
echo "		--> patching the broker to expose the JMX management console"
oc get dc/broker && { oc deploy broker --cancel && oc patch dc/broker -p '{"spec": {"template": {"spec": {"containers":[{"name":"broker", "ports": [{"containerPort":8778, "name":"jolokia"}]}]}}}}' && oc deploy dc/broker ; } || { echo "WARNING: could update broker -- JMX console may not be available" ; } 

echo "	--> Deploy all routers"
for ROUTER in router-{a..d} ; do
	echo "Deploy the ${ROUTER}"
	oc get dc/${ROUTER} || oc new-app --name=${ROUTER} --image-stream=amq-interconnect -e QDROUTER_CONF=/etc/qpid-dispatch/${ROUTER}.conf
	sleep 1s
	oc get dc/${ROUTER} && { oc deploy ${ROUTER} --cancel && oc volume dc/${ROUTER} --remove --all --confirm && oc volume dc/${ROUTER} --add --mount-path=/etc/qpid-dispatch --configmap-name=network-config --type=configmap --default-mode=420 && oc deploy dc/${ROUTER}  && oc set probe dc/${ROUTER} --readiness --period-seconds=5 --open-tcp=6000 ; } || { echo "WARNING: could update ${ROUTER}" ; } 
done

oc expose service router-a --port=8080

echo "Done."