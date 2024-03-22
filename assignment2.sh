#!/bin/bash
set -euo pipefail

# Log messages
log() {
    echo "[INFO] $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root."
    exit 1
fi

# Update netplan configuration 
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:  #
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses:
          - 192.168.16.2
      routes:
        - to: 0.0.0.0/0
          via: 192.168.16.2
EOF

# Update /etc/hosts
sed -i '/192.168.16.21/d' /etc/hosts
echo "192.168.16.21 server1" >> /etc/hosts

# Enable UFW
ufw enable

# Allow SSH on the mgmt network
ufw allow in on mgmt to any port 22

# Allow HTTP on both interfaces
ufw allow http

# Allow web proxy on both interfaces
ufw allow 8080

# Create user accounts
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do
    adduser --disabled-password --gecos "" "$user"
    usermod -s /bin/bash "$user"
    mkdir -p "/home/$user/.ssh"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/$user/.ssh/authorized_keys"
    chown -R "$user:$user" "/home/$user/.ssh"
done

# Grant sudo access to dennis
usermod -aG sudo dennis

# Install apache2
apt-get update
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2

# Report completion
log "Configuration and software installation completed successfully."
