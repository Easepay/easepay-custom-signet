FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential libtool autotools-dev automake \
    pkg-config bsdmainutils python3 libssl-dev \
    libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-chrono-dev libboost-test-dev libboost-thread-dev \
    libdb-dev libdb++-dev python3-pip jq

# Clone Bitcoin Core
RUN apt-get install -y git
RUN git clone https://github.com/bitcoin/bitcoin.git

# Build Bitcoin Core
WORKDIR /bitcoin
RUN ./autogen.sh
RUN ./configure
RUN make

# Copy, Prepare Signet configuration and run signet script
COPY generate_signet.sh .
RUN chmod +x generate_signet.sh

# Copy Bitcoin.conf file
COPY bitcoin.conf /root/.bitcoin/bitcoin.conf

# Copy the generate.py script from the Bitcoin core source
COPY --from=0 /bitcoin/contrib/signet/miner.py /usr/local/bin/
RUN chmod +x /usr/local/bin/miner.py


# Expose necessary ports
EXPOSE 38333 38332

# Start Bitcoin Core
CMD ["./generate_signet.sh"]
