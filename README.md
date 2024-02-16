# Custom Easepay Bitcoin Signet Docker Setup script

# Overview

This repository contains a Docker setup for running a custom Bitcoin Signet. Signet is a test network (testnet) for Bitcoin, allowing developers to test Bitcoin applications and experiments without risking real funds and without the unpredictability of the public testnet.

The provided Dockerfile and scripts automate the process of setting up a custom Signet, generating necessary keys and configuration, and running a Bitcoin node configured for this custom Signet.

# Features

* Custom Signet Configuration: Allows creating a private Signet with custom consensus rules.
* Automated Key and Script Generation: Automatically generates the necessary keys and block script for the Signet.
* Dockerized Environment: Ensures a consistent and isolated environment for running the Bitcoin node.
* Block Mining Capabilities: Includes scripts to mine blocks on the custom Signet.

## Prerequisites

* Docker
* Git (for cloning the repository)

# Repository Contents
* `Dockerfile`: Instructions for building the Docker image with Bitcoin Core and necessary dependencies.
* `generate_signet.sh`: Shell script to set up the custom Signet, generate keys, define the block script, and start the Bitcoin node.
* `bitcoin.conf`: Bitcoin.conf file for our signet setup that contains our signetchallenge

* `generate.py`: Python script used for mining blocks on the custom Signet.


# Setup and Usage

## Building the Docker Image

1. Clone this repository.
2. Navigate to the repository directory.
3. Build the Docker image:


```docker build -t bitcoin-signet .```

## Running the Custom Signet Node

```docker run -d -p 38333:38333 -p 38332:38332 bitcoin-signet```

The generate_signet.sh script will execute within the container, setting up the custom Signet and starting the Bitcoin node.

** NOTE **:  the signet challenge parameter (pubkey) should be generated before building
the docker image. this can be done on your local machine. This approach would mean you would have a fixed public key for your Signet, which isn't such a big deal for testing. It's also possible to update the `generate_script.sh` script to dynamically create the bitcoin.conf after generating the public key. I ran into some issues trying to do this, you may have the time, so Knock yourself out and create a PR if you get it done.

## POINTERS
* The script would first start bitcoind in regtest mode, generate the key pair, construct the signetchallenge with the new public key, 
* Create the bitcoin.conf with this signetchallenge, and then restart bitcoind in Signet mode with the new configuration.

`Warning`: This approach is more complex but allows for a fresh public key each time you build and run the container.

## Accessing the Node
* The Bitcoin node's JSON-RPC interface will be available on port 38332 of the host machine... This would be deployed for easy connection for all team members who need to interact with it. 

* The Bitcoin P2P network for this Signet operates on port 38333.

## Customizing the Signet
You can modify the generate_signet.sh script to change the Signet parameters, such as the block signing keys or other consensus rules.

## Security Considerations
This setup is intended for development and testing purposes only. Do not use it with real funds or sensitive data.
it is your responsibility to ensure appropriate security measures are in place if exposing the node to public networks.

## Contributing
Contributions to this project are welcome. Please ensure that any changes are tested with the Docker setup before submitting a pull request.
