#!/bin/sh

# Define container name = should match name in docker-compose
BICOIND_CONTAINER_NAME="easepay-bitcoind"

# Start Bitcoind in Regtest mode
docker exec -it $BITCOIND_CONTAINER_NAME bitcoind -regtest -daemon

# Wait for Bitcoind to start running
sleep 5

# Generate a new address and get the private key and public key
ADDR=$(docker exec $BITCOIND_CONTAINER bitcoin-cli -regtest getnewaddress)
PRIVKEY=$(docker exec $BITCOIND_CONTAINER bitcoin-cli -regtest dumpprivkey $ADDR)
PUBKEY=$(docker exec $BITCOIND_CONTAINER bitcoin-cli -regtest getaddressinfo $ADDR | jq -r '.pubkey')

# Echo the generated values
echo "Address: $ADDR"
echo "Private Key: $PRIVKEY"
echo "Public Key: $PUBKEY"

# Optionally, stop the regtest node
# docker exec $BITCOIND_CONTAINER bitcoin-cli -regtest stop


