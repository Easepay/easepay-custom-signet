#!/bin/sh
set -Eeuo pipefail

# Define the path to your Bitcoin data directory
DATADIR="/root/signet-custom"

# Ensure the debug.log file exists
touch $DATADIR/debug.log

# Show and Tail Bitcoin debug log
tail -n +1 -f $DATADIR/debug.log || true
echo "Tailing the Bitcoin debug log. press Ctrl+c to stop." 
