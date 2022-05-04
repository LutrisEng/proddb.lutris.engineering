#!/bin/bash

set -euxo pipefail

echo "$FLY_REGION $FLY_ALLOC_ID"
exec cockroach sql --insecure
