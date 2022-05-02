#!/bin/bash

set -euxo pipefail

if [[ "$FLY_REGION" = "dfw" ]]
then
    exec cloudflared tunnel --no-autoupdate run --token $CLOUDFLARE_TUNNEL_TOKEN
else
    echo "Not running cloudflared outside dfw"
    sleep infinity
fi
