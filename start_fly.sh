#!/bin/bash

set -euxo pipefail

alloc=$(echo $FLY_ALLOC_ID | awk -F '-' '/1/ {print $1}')
hostname="$alloc.vm.$FLY_APP_NAME.internal"

echo "Hostname: $hostname"

exec cockroach start \
    --insecure \
    --store=path=/cockroach \
    --locality=region=$FLY_REGION \
    --cluster-name=$FLY_APP_NAME \
    --join=dfw.$FLY_APP_NAME.internal,sjc.$FLY_APP_NAME.internal,ams.$FLY_APP_NAME.internal,$FLY_APP_NAME.internal \
    --advertise-addr=$hostname
