#!/bin/bash

# Update and install MongoDB
yum update -y
amazon-linux-extras enable corretto8
amazon-linux-extras install java-openjdk11
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo rpm --import -
tee -a /etc/yum.repos.d/mongodb-org-6.0.repo << EOL
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOL
yum install -y mongodb-org

# Configure MongoDB
systemctl start mongod
systemctl enable mongod

# Allow remote access to MongoDB (optional, be cautious with security)
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Setup MongoDB Replica Set
cat > /tmp/rs.js <<-EOF
  rs.initiate()
  rs.add("${element(aws_instance.mongodb[*].private_ip, 1)}:27017")
  rs.add("${element(aws_instance.mongodb[*].private_ip, 2)}:27017")
  rs.status()
EOF

# Execute the Replica Set configuration script
mongo --eval "rs.initiate()"  # Initial setup
sleep 10  # Wait for the primary to stabilize
mongo < /tmp/rs.js
