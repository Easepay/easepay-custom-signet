FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential libtool autotools-dev automake \
    pkg-config bsdmainutils python3 libssl-dev \
    libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-chrono-dev libboost-test-dev libboost-thread-dev \
    libdb-dev libdb++-dev

# Clone Bitcoin Core
RUN apt-get install -y git
RUN git clone https://github.com/bitcoin/bitcoin.git

# Build Bitcoin Core
WORKDIR /bitcoin
RUN ./autogen.sh
RUN ./configure
RUN make

# Prepare Signet configuration
RUN mkdir /root/.bitcoin
COPY bitcoin.conf /root/.bitcoin/

# Expose necessary ports
EXPOSE 38333 38332

# Start Bitcoin Core
CMD ["/bitcoin/src/bitcoind"]
