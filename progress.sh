#!/usr/bin/bash

# Load Environment Variables
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

export ETH_RPC_URL=http://localhost:8545
L2_URL=https://symbiosis.calderachain.xyz/http
POLL_INTERVAL=15
TIMES_POLLED=0

INITIAL_BLOCK=$(cast block-number --rpc-url $ETH_RPC_URL)

echo "Syncing replica from block: $INITIAL_BLOCK"

while true; do
    TIMES_POLLED=$((TIMES_POLLED + 1))
    sleep $POLL_INTERVAL
    CURRENT_BLOCK=$(cast block-number --rpc-url $ETH_RPC_URL)

    PER_INTERVAL=$(( (CURRENT_BLOCK - INITIAL_BLOCK) / TIMES_POLLED ))
    PER_MIN=$(( PER_INTERVAL * (60 / POLL_INTERVAL) ))
    echo "Blocks per minute: $PER_MIN"

    # How many more blocks do we need?
    HEAD=$(cast block-number --rpc-url $L2_URL)
    BEHIND=$((HEAD - CURRENT_BLOCK))

    if [ $HEAD -eq $CURRENT_BLOCK ]; then
        echo "Sync complete!"
        exit 0
    elif [ $PER_MIN -eq 0 ]; then
        echo "Not currently syncing. Checking again in $POLL_INTERVAL seconds."
    else
        TOTAL_MINUTES=$((BEHIND / PER_MIN))
        DAYS=$((TOTAL_MINUTES / 1440))
        HOURS=$(( (TOTAL_MINUTES % 1440) / 60 ))
        MINUTES=$((TOTAL_MINUTES % 60))

        if [ $DAYS -gt 0 ]; then
            echo "Estimated time until sync completed: $DAYS days, $HOURS hours"
        elif [ $HOURS -gt 0 ]; then
            echo "Estimated time until sync completed: $HOURS hours, $MINUTES minutes"
        else
            echo "Estimated time until sync completed: $MINUTES minutes"
        fi
    fi

    echo "------------------------------"
done
