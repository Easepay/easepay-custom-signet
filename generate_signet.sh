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
PUBKEY=$(./src/bitcoin-cli -regtest getaddressinfo $ADDR | jq -r .scriptPubKey)

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


# Navigate to the src directory(this assume that Docker workdir is set to the root)
cd src/

# Define neccessary commands and paths
MINER="../contrib/signet/miner"
GRIND="./bitcoin-util grind"
CLI="./bitcoin-cli -datadir=$datadir"

# Calibrate to find a suitable nbits value (Note: it is possible to adjust this as you see fit)
NBITS=$($MINER calibrate --grind-cmd="$GRIND" --seconds=160)

# Generate an address for receiving mining rewards
ADDR=$($CLI -signet getnewaddress)

# Advanced Block Generation Process
# Generate and create a block template. This generates a PSBT, processes it, and submits the block to the Signet network
$CLI -signet getblocktemplate '{"rules": ["signet","segwit"]}' \
  | $MINER --cli="$CLI" genpsbt --address="$ADDR" \
  | $CLI -signet -stdin walletprocesspsbt \
  | jq -r .psbt \
  | $MINER --cli="$CLI" solvepsbt --grind-cmd="$GRIND" \
  | $CLI -signet -stdin submitblock


# Optional for continues mining 
# $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --address="$ADDR" --nbits=$NBITS --ongoing

# Stop the custom Signet node
./bitcoin-cli -datadir=$datadir stop

