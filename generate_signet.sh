#!/bin/sh

# Start Bitcoind in Signet mode
/usr/local/bin/bitcoind -signet -daemon 
echo "wating for signet bitcoind to start..."
while ! /usr/local/bin/bitcoin-cli -signet getconnectioncount 2>/dev/null 1>&2; do
    echo -n ".";
    sleep 1;
done
echo "started"

# check if custom_signet_wallet exist, create it if not
if ! /usr/local/bin/bitcoin-cli -signet listwallets | grep -q "custom_signet_wallet"; then
    echo "Creating wallet: custom_signet_wallet"
    /usr/local/bin/bitcoin-cli -signet createwallet "custom_signet_wallet"
  else 
     echo "Wallet custom_signet-wallet already exists"
  fi

# Generate mew address and keys
ADDR=$(/usr/local/bin/bitcoin-cli -signet -rpcwallet="custom_signet_wallet" getnewaddress '' bech32)
if [ -z "$ADDR" ]; then
    echo "Failed to get new address"
fi

PRIVKEY=$(/usr/local/bin/bitcoin-cli -signet -rpcwallet="custom_signet_wallet" dumpprivkey $ADDR)
PUBKEY=$(/usr/local/bin/bitcoin-cli -signet -rpcwallet="custom_signet_wallet" getaddressinfo $ADDR | jq -r .pubkey)

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
/usr/local/bin/bitcoind -datadir=$datadir -signet -wallet="test"

# Wait for the custom signet to start
echo "Waiting for custom Signet bitcoind to start"
while ! /usr/local/bin/bitcoin-cli -datadir=$datadir getconnectioncount 2>/dev/null 1>&2; do
     echo -n ".";
     sleep 1;
done
echo "Started"

# Import the private key to the custom signet node
/usr/local/bin/bitcoin-cli -datadir=$datadir importprivkey "$PRIVKEY"

# Generate a new address for mining
NADDR=$(/usr/local/bin/bitcoin-cli -datadir=$datadir getnewaddress)

# Examples from
# https://github.com/bitcoin/bitcoin/pull/19937#issuecomment-696419619


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



# -wallet="custom_signet_wallet" #Wallet name must match the name we have in signet_challenge script