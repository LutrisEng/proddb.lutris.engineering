#!/bin/bash

set -euxo pipefail

exec fly ssh console -C run_sql_console.sh
