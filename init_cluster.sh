#!/bin/bash

set -euxo pipefail

exec cockroach init \
    --insecure \
    --store=path=/cockroach \
    --cluster-name=$FLY_APP_NAME
