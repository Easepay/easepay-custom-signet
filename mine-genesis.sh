#!/bin/bash
ADDR=${ADDR:-$(bitcoin-cli getnewaddress)}
NBITS=${NBITS:-"1e0377ae"} #minimum difficulty in signet=this can be adjusted to reasonable time.
miner --cli="bitcoin-cli" generate --address=$ADDR --grind-cmd="bitcoin-util grind" --nbits=$NBITS --set-block-time=$(date +%s)