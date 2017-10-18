#!/bin/bash

# Additional Configuration
# None

. ./setup.sh

echo "The basic infrastructure should be available at this point; press enter to continue" && read

. ./setup-send-messages.sh

echo "Router A now holds 5 messages, which are now cached at the broker waiting for delivery -- but the destination is not available" && read

. ./setup-connect-router-c-and-d.sh

echo "Router A now holds 5 messages, which are now cached at the broker waiting for delivery -- but the destination is not available" && read

. ./setup-receive-messages.sh

echo "Messages should have been received"

CONFIGURATION_DISPLAY=false
