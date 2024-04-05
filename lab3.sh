#!/bin/bash

# function to execute a command and check if it succeeded
execute() {
    if ! "$@"; then
        echo "An error occurred executing \"$@\""
        exit 1
    fi
}

verbose_flag=""

# check if we're running in verbose mode
if [ "$1" == "-verbose" ]; then
    verbose_flag="-verbose"
fi

# transfer and execute the script on server1 with elevated permissions
execute scp configure-host.sh remoteadmin@server1-mgmt:/root
execute ssh remoteadmin@server1-mgmt -- sudo /root/configure-host.sh $verbose_flag -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

# transfer and execute the script on server2 with elevated permissions
execute scp configure-host.sh remoteadmin@server2-mgmt:/root
execute ssh remoteadmin@server2-mgmt -- sudo /root/configure-host.sh $verbose_flag -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

# update the local /etc/hosts file with elevated permissions
execute sudo ./configure-host.sh $verbose_flag -hostentry loghost 192.168.16.3
execute sudo ./configure-host.sh $verbose_flag -hostentry webhost 192.168.16.4

echo "All operations completed successfully."
