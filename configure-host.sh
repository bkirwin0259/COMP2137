#!/bin/bash

# check if we're in verbose mode
verbose_mode=false

log_change() {
    if [ "$verbose_mode" = true ]; then
        echo "$1"
    fi
    logger "$1"
}

# update hostname
update_hostname() {
    local desired_name="$1"
    local current_name
    current_name=$(hostname)

    if [ "$current_name" != "$desired_name" ]; then
        echo "$desired_name" > /etc/hostname
        hostname "$desired_name"
        log_change "Hostname changed from $current_name to $desired_name"
    else
        log_change "Hostname is already set to $desired_name, no change needed."
    fi
}

# update IP address and apply the settings
update_ip_address() {
    local desired_ip="$1"
    local lan_interface
    lan_interface=$(ip r | grep default | awk '{print $5}')

    if [ -n "$lan_interface" ]; then
        local netplan_file="/etc/netplan/01-netcfg.yaml"
        sed -i "s/addresses:.*/addresses: [$desired_ip\/24]/" "$netplan_file"
        netplan apply
        
        log_change "IP address updated to $desired_ip on $lan_interface"
    else
        log_change "No LAN interface found. Cannot update IP address."
    fi
}

# update the /etc/hosts file
update_hosts_file() {
    local name="$1"
    local ip="$2"
    local hosts_entry="$ip $name"
    
    if ! grep -q "$hosts_entry" /etc/hosts; then
        echo "$hosts_entry" >> /etc/hosts
        log_change "Updated /etc/hosts with entry: $hosts_entry"
    else
        log_change "/etc/hosts already contains the entry: $hosts_entry, no change needed."
    fi
}

# ignore the TERM, HUP, and INT signals
trap '' TERM HUP INT

# Parse the command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) verbose_mode=true ;;
        -name) shift; update_hostname "$1" ;;
        -ip) shift; update_ip_address "$1" ;;
        -hostentry) shift; update_hosts_file "$1" "$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

exit 0
