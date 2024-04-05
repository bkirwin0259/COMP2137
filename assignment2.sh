#!/bin/bash
set -euo pipefail

# Log message func
log() {
    echo "[STATUS REPORT] $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root."
    exit 1
fi

# Update netplan configuration 
cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
        - 192.168.16.21/24
EOF
log "Netplan configuration updated."

# Update /etc/hosts
if grep -q "192.168.16.21 server1" /etc/hosts; then
    log "/etc/hosts already updated."
else
    sed -i '/192.168.16.21/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
    log "/etc/hosts updated."
fi

# Enable UFW and set rules
ufw enable
ufw allow in on mgmt to any port 22
log "Firewall configured for SSH on mgmt interface."

# Allow HTTP and proxy ports on ens192
ufw allow in on ens192 from any to any port 80 proto tcp
ufw allow in on ens192 from any to any port 3128 proto tcp
log "Firewall configured for HTTP and proxy on ens192 interface."

# Create user accounts with SSH keys
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
        log "User $user already exists."
    else
        adduser --disabled-password --gecos "" "$user"
        usermod -s /bin/bash "$user"
        mkdir -p "/home/$user/.ssh"
        cat <<EOF >> "/home/$user/.ssh/authorized_keys"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
EOF
        chown -R "$user:$user" "/home/$user/.ssh"
        log "User $user created and SSH keys added."
    fi
done

# Grant sudo access to dennis
if groups dennis | grep -q "\bsudo\b"; then
    log "Sudo access already granted to dennis."
else
    usermod -aG sudo dennis
    log "Sudo access granted to dennis."
fi

# Install and configure Apache2
if dpkg -l | grep -q "apache2"; then
    log "Apache2 already installed."
else
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    log "Apache2 installed and configured."
fi

# Report completion
log "Script execution complete."
