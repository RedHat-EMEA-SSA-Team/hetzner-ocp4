#!/bin/bash
set -eu
# Set current user in nss_wrapper
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /container-scripts/passwd.template > /container-scripts/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/container-scripts/passwd
export NSS_WRAPPER_GROUP=/etc/group


exec bash