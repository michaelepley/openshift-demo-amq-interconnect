#!/bin/bash

# Additional Configuration

CONFIGURATION_DISPLAY=false

echo "Check the status of all routers"
for ROUTER in router-{a..d} ; do
	. ./status-router.sh ${ROUTER}
done