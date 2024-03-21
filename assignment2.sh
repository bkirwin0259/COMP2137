#!/bin/bash

# Display message 
display_message() {
    echo "-----------------------------------------------------"
    echo ">> $1"
    echo "-----------------------------------------------------"
}

# Server configuration
display_message "Initializing Server Configuration"

# Update system and install packages
display_message "Updating system and installing necessary packages"
sudo apt update
sudo apt upgrade -y
sudo apt install -y apache2 squid ufw

# Network interface config
display_message "Configuring network interface"
cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOF
netplan apply

# Update /etc/hosts file
display_message "Updating /etc/hosts file"
sudo sed -i '/192.168.16.21/s/^/#/' /etc/hosts
sudo bash -c 'echo "192.168.16.21    server1" >> /etc/hosts'

# Configure firewall with UFW
display_message "Configuring firewall with UFW"
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow from 192.168.16.0/24 to any port 3128 # squid proxy
sudo ufw --force enable

# Create user accounts and configure SSH keys
display_message "Creating user accounts and configuring SSH keys"
declare -A users=(
    ["dennis"]="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
    ["aubrey"]=""
    ["captain"]=""
    ["snibbles"]=""
    ["brownie"]=""
    ["scooter"]=""
    ["sandy"]=""
    ["perrier"]=""
    ["cindy"]=""
    ["tiger"]=""
    ["yoda"]=""
)

for username in "${!users[@]}"; do
    display_message "Creating user: $username"
    if ! id "$username" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$username"
        if [[ -n "${users[$username]}" ]]; then
            sudo mkdir -p /home/$username/.ssh
            sudo bash -c "echo '${users[$username]}' >> /home/$username/.ssh/authorized_keys"
            sudo chown -R $username:$username /home/$username/.ssh
            sudo chmod 700 /home/$username/.ssh
            sudo chmod 600 /home/$username/.ssh/authorized_keys
        fi
        if [[ "$username" == "dennis" ]]; then
            sudo usermod -aG sudo $username
        fi
    else
        echo "User $username already exists."
    fi
done

# Restart services
display_message "Restarting services"
sudo systemctl restart apache2 squid

# Display completion message
display_message "Server configuration completed successfully"
