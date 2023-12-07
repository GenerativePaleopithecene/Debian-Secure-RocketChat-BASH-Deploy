#!/bin/bash
# https://github.com/GenerativePaleopithecene/Debian-Secure-RocketChat-BASH-Deploy
# gpl3
# Use a fresh Debian Minimal Server install to avoid any problems. The thing this script doesn't do is create an admin user in MongoDB.
# Check out the comment section in the script and it will give you the commands you need in the MongoDB shell. 

# Update and Upgrade System
apt update && apt upgrade -y

# Into Entropy
apt install haveged

# Install MongoDB
apt install -y mongodb-server

# Configure MongoDB Security
sed -i 's/^#security:/security:\n  authorization: enabled/' /etc/mongod.conf
sed -i 's/^#bindIp: 127.0.0.1/bindIp: 127.0.0.1/' /etc/mongod.conf
systemctl restart mongod

# Create an admin user in MongoDB (run these commands in the mongo shell)
# mongo
# use admin
# db.createUser({user: "admin", pwd: "yourpassword", roles:[{role: "root", db: "admin"}]})

# Install Node.js (Rocket.Chat recommends a specific version)
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt install -y nodejs

# Create a Rocket.Chat user
useradd -M -d /opt/Rocket.Chat -s /bin/false rocketchat
chown -R rocketchat:rocketchat /opt/Rocket.Chat

# Download and Install Rocket.Chat
curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp
cd /tmp/bundle/programs/server && npm install
mv /tmp/bundle /opt/Rocket.Chat

# Create a Rocket.Chat user
useradd -M -d /opt/Rocket.Chat rocketchat

# Set up a Systemd service for Rocket.Chat
cat << EOF > /etc/systemd/system/rocketchat.service
[Unit]
Description=Rocket.Chat Server
After=network.target remote-fs.target nss-lookup.target mongodb.service
Wants=mongodb.service

[Service]
ExecStart=/usr/local/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat ROOT_URL=http://your-domain.com:3000/ PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Rocket.Chat service
systemctl start rocketchat
systemctl enable rocketchat

# Install Fail2Ban
apt install -y fail2ban

# Fail2Ban Configuration
cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600 # Duration of IP ban (in seconds)
findtime = 600 # Time frame for counting retries (in seconds)
maxretry = 5 # Max retries before banning

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

# Restart Fail2Ban to apply changes
systemctl restart fail2ban

# Install Auditd
apt install -y auditd

# Auditd Configuration
cat << EOF > /etc/audit/audit.rules
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k actions
-w /var/log/auth.log -p wa -k auth
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b64 -S mount -k export
EOF

# Restart Auditd to apply changes
systemctl restart auditd

# Harden SSH Access
sed -i 's/^#*PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*Port 22/Port 2222/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
systemctl restart sshd

# Setup UFW Firewall
ufw enable
ufw allow 2222/tcp # New SSH port
ufw allow 3000/tcp # Rocket.Chat port
ufw allow 'Nginx Full'


## Self-Signed Certificate
mkdir /etc/ssl/mycerts
chmod 700 /etc/ssl/mycerts
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/mycerts/selfsigned.key -out /etc/ssl/mycerts/selfsigned.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=your-domain.com"
# The certificate and key are stored in /etc/ssl/mycerts

# Install Nginx
apt install -y nginx

# Set up Nginx as a reverse proxy for Rocket.Chat
cat << EOF > /etc/nginx/sites-available/rocketchat
server {
    listen 80;
    server_name your-domain.com; # Replace with your domain or server IP

    location / {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forward-Proto http;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }
}
EOF

ln -s /etc/nginx/sites-available/rocketchat /etc/nginx/sites-enabled/rocketchat
rm /etc/nginx/sites-enabled/default

# Restart Nginx to apply changes
systemctl restart nginx

# Reverse Proxy 
server {
    listen 443 ssl;
    server_name your-domain.com; # Replace with your domain or server IP

    ssl_certificate /etc/ssl/mycerts/selfsigned.crt; # Path to your SSL certificate
    ssl_certificate_key /etc/ssl/mycerts/selfsigned.key; # Path to your SSL private key

    # ... [rest of the server block]
}

# HTTP server to redirect all 80 traffic to SSL/HTTPS
server {
    listen 80;
    server_name your-domain.com; # Replace with your domain or server IP
    return 301 https://\$host\$request_uri;
}

