#!/bin/sh

# Start Bitcoind in regtest mode
./src/bitcoind -regtest -daemon -wallet="test" #change wallet name
echo "wating for regtest bitcoind to start..."
while ! ./src/bitcoin-cli -regtest getconnectioncount 2>/dev/null 1>&2; do
    echo -n ".";
    sleep 1;
done
echo "started"

# Generate mew address and keys
ADDR=$(./src/bitcoin-cli -regtest getnewaddress '' bech32)
PRIVKEY=$(./src/bitcoin-cli -regtest dumpprivkey $ADDR)
PUBKEY=$(./src/bitcoin-cli -regtest getaddressinfo $ADDR | jq -r .pubkey)

# Calculate script length and keys
LENX2=$(printf $PUBKEY | wc -c)
LEN=$((LENX2/2))
LENHEX=$(printf '%x\n' $LEN)
SCRIPT="51${LENHEX}${PUBKEY}51ae"

# Output the generated values
cat <<EOF
ADDR=$ADDR
PRIVKEY=$PRIVKEY
PUBKEY=$PUBKEY
SCRIPT=$SCRIPT
EOF

# Stop the regtest node
./src/bitcoin-cli -regtest stop

# Create a new directory for the custom signet
datadir=/root/signet-custom
mkdir $datadir

# Write the custom signet configuration
cat > $datadir/bitcoin.conf <<EOF
signet=1
[signet]
daemon=1
signetchallenge=$SCRIPT
EOF

# Start bitcoind with the custom signet configuration
./src/bitcoind -datadir=$datadir -wallet="test"

# Wait for the custom signet to start
echo "Waiting for custom Signet bitcoind to start"
while ! ./src/bitcoin-cli -datadir=$datadir getconnectioncount 2>/dev/null 1>&2; do
     echo -n ".";
     sleep 1;
done
echo "Started"

# Import the private key to the custom signet node
./src/bitcoin-cli -datadir=$datadir importprivkey "$PRIVKEY"

# Generate a new address for mining
NADDR=$(./src/bitcoin-cli -datadir=$datadir getnewaddress)

# Examples from
# https://github.com/bitcoin/bitcoin/pull/19937#issuecomment-696419619


# Start mining blocks
# Include miner.py script into docker
# Generate the first block to your Address using a specific block time
./contrib/signet/miner.py --cli="./src/bitcoin-cli -datadir=$datadir" generate 1 --set-block-time=$(date +%s) --address="$NADDR" --grind-cmd='./src/bitcoin-util grind'

# (WIP)
#../contrib/signet/miner.py --cli="./bitcoin-cli -datadir=$datadir" generate 1 --block-time=1 --address="$NADDR" --backdate 0
#../contrib/signet/miner.py --cli="./bitcoin-cli -datadir=$datadir" generate 1 --block-time=1 --descriptor="wpkh(...)#..." --secondary


# Generate and create a block template. this generate a PBST, process it, and submit the block to the signet network
./src/bitcoin-cli -datadir=$datadir getblocktemplate '{"rules": ["signet","segwit"]}' \
  | ./contrib/signet/miner.py --cli="./src/bitcoin-cli -datadir=$datadir" genpsbt --address="$NADDR" \
  | ./src/bitcoin-cli -datadir=$datadir -stdin walletprocesspsbt

# Solve and submit a PBST
./contrib/signet/miner.py solvepsbt --grind-cmd='./src/bitcoin-util grind' | ./src/bitcoin-cli -datadir=$datadir submitblock

# Stop the custom Signet node
./bitcoin-cli -datadir=$datadir stop
