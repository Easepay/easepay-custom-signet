# Use a base image with the necessary runtime dependencies
FROM ubuntu

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
python3 libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev \
libboost-chrono-dev libboost-test-dev libboost-thread-dev libdb-dev libdb++-dev python3-pip jq

# Copy and prepare script for signet configurations
COPY generate_signet.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_signet.sh

# Copy Bitcoin.conf file
COPY bitcoin.conf /root/.bitcoin/bitcoin.conf

# Copy the logtail.sh script
COPY logtail.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/logtail.sh

# Copy the .bashrc file to the container's root directory
COPY .bashrc /root/.bashrc

# Expose necessary ports (update these if needed)
EXPOSE 18443 
# EXPOSE 38333 

# Start Bitcoin Core
CMD ["/usr/local/bin/generate_signet.sh"]

