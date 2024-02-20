# Build stage for Bitcoin Core
FROM ubuntu as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential libtool autotools-dev automake \
    pkg-config bsdmainutils python3 libssl-dev \
    libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-chrono-dev libboost-test-dev libboost-thread-dev \
    libdb-dev libdb++-dev python3-pip jq git

# Clone and build Bitcoin Core
RUN git clone --depth 1 https://github.com/bitcoin/bitcoin.git 

# Build Bitcoin core
WORKDIR /bitcoin
RUN ./autogen.sh
RUN ./configure
RUN make

# Application stage
FROM ubuntu

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
python3 libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev \
libboost-chrono-dev libboost-test-dev libboost-thread-dev libdb-dev libdb++-dev python3-pip jq

# Copy Binaries and scripts from the builder stage
COPY --from=builder /bitcoin/src/bitcoind /usr/local/bin/
COPY --from=builder /bitcoin/src/bitcoin-cli /usr/local/bin/
COPY --from=builder /bitcoin/contrib/signet/miner /usr/local/bin/
RUN chmod +x /usr/local/bin/miner

# Copy and prepare sript for signet configurations
COPY generate_signet.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_signet.sh

# Copy Bitcoin.conf file
COPY bitcoin.conf /root/.bitcoin/bitcoin.conf

# Copy the logtail.sh script
COPY logtail.sh /usr/local/bin/
RUN chmod +x usr/local/bin/logtail.sh

# Copy the .bashrc file to the container's root directory
COPY .bashrc /root/.bashrc

# Expose necessary ports
EXPOSE 38333 38332

# Start Bitcoin Core
CMD ["usr/local/bin/generate_signet.sh"]
