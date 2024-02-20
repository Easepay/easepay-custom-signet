#!/bin/bash

# Create a new wallet
WALLET_NAME="custom_signet_wallet"
bitcoin-cli -signet createwallet "$WALLET_NAME"

# Generate a new address and retrieve the public key
ADDRESS=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" getnewaddress)
PUBKEY=$(bitcoin-cli -signet -rpcwallet="$WALLET_NAME" getaddressinfo "$ADDRESS" | jq -r .pubkey)

# Construct the signetchallenge script
SIGNETCHALLENGE="5121${PUBKEY}51ae"

# Output the signetchallenge
echo "signetchallenge: $SIGNETCHALLENGE"
