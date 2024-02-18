# Use bash completion, if available
alais bitcoin-cli="bitcoin-cli  -datadir=/root/signet-custom"

# Check if an interactive shell is running
if [ -n "$PS1" ]; then
    # Source bash completion, if its available
    if [ -f /usr/share/bash-completion/bash_completion]; then
        ./usr/share/bash-completion/bash_completion

      fi
   fi
