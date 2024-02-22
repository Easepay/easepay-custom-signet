# Use a base image with the necessary runtime dependencies
FROM ubuntu

# Install runtime dependencies
RUN apt-get update && apt-get install -y jq

# Copy and prepare script for signet configurations
COPY generate_signet.sh /usr/local/bin/generate_signet.sh
RUN chmod +x /usr/local/bin/generate_signet.sh

# Copy Bitcoin.conf file
COPY bitcoin.conf /root/.bitcoin/bitcoin.conf

# Copy the logtail.sh script
COPY logtail.sh /usr/local/bin/logtail.sh
RUN chmod +x /usr/local/bin/logtail.sh

# Copy the .bashrc file to the container's root directory
COPY .bashrc /root/.bashrc

# Expose necessary ports (update these if needed)
EXPOSE 18443 
# EXPOSE 38333 

# Start Bitcoin Core
CMD ["/usr/local/bin/generate_signet.sh"]

