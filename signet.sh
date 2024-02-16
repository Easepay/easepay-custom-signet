#!/bin/sh

cd ~/src/bitcoin/src

./bitcoind -regtest -daemon=1 -wallet="test"
printf "Waiting for regtest bitcoind to start"
while ! ./bitcoin-cli -regtest getconnectioncount 2>/dev/null 1>&2
do printf .; sleep 1
done; echo

ADDR=$(./bitcoin-cli -regtest getnewaddress '' bech32)
PRIVKEY=$(./bitcoin-cli -regtest dumpprivkey $ADDR)
PUBKEY=$(./bitcoin-cli -regtest getaddressinfo $ADDR | jq -r .pubkey)

LENX2=$(printf $PUBKEY | wc -c)
LEN=$((LENX2/2))
LENHEX=$(echo "obase=16; $LEN" | bc)
SCRIPT=$(echo 51${LENHEX}${PUBKEY}51ae)

cat <<EOF
ADDR=$ADDR
PRIVKEY=$PRIVKEY
PUBKEY=$PUBKEY
SCRIPT=$SCRIPT
EOF

./bitcoin-cli -regtest stop 2>&1

datadir=$HOME/signet-custom-$$
mkdir $datadir
cat > $datadir/bitcoin.conf <<EOF
signet=1
[signet]
daemon=1
signetchallenge=$SCRIPT
EOF

./bitcoind -datadir=$datadir -wallet="test"

printf "Waiting for custom Signet bitcoind to start"
while ! ./bitcoin-cli -datadir=$datadir getconnectioncount 2>/dev/null 1>&2
do printf .; sleep 1
done; echo

./bitcoin-cli -datadir=$datadir importprivkey "$PRIVKEY"
NADDR=$(./bitcoin-cli -datadir=$datadir getnewaddress)

# Examples from
# https://github.com/bitcoin/bitcoin/pull/19937#issuecomment-696419619

../contrib/signet/generate.py --cli="./bitcoin-cli -datadir=$datadir" generate 1 --block-time=1 --address="$NADDR" --grind-cmd='./bitcoin-util grind'
#../contrib/signet/generate.py --cli="./bitcoin-cli -datadir=$datadir" generate 1 --block-time=1 --address="$NADDR" --backdate 0
#../contrib/signet/generate.py --cli="./bitcoin-cli -datadir=$datadir" generate 1 --block-time=1 --descriptor="wpkh(...)#..." --secondary

./bitcoin-cli -datadir=$datadir getblocktemplate '{"rules": ["signet","segwit"]}' \
  | ../contrib/signet/generate.py --cli="./bitcoin-cli -datadir=$datadir" genpsbt --address="$NADDR" \
  | ./bitcoin-cli -datadir=$datadir -stdin walletprocesspsbt

#../contrib/signet/generate.py solvepsbt --grind-cmd='./bitcoin-util grind' | ./bitcoin-cli -datadir=$datadir submitblock

./bitcoin-cli -datadir=$datadir stop
