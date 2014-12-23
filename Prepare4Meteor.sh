#!/bin/sh
set -u
set -e

# :::::::::::::::::::::::::::::::::::: EDIT THE FOLLOWING LOCAL VARIABLES  :::::::::::::::::::::::::::::::::::: 
# SSH Port:
_PORT="7648"

# Username of the New User
_USERNAME="xaxanoulis7"

# The User's Home DIR
_USERDIR="/home/$_USERNAME"

# New Nginx Site Name
_SITENAME="test.com"

# Your SSH Public Key
_SSHkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local"

# Your Nginx Site Configuration File Path
_SITE_CONF_PATH="$_USERDIR/test.conf"

# Your Upstart Configuration File Path
_UPSTART_CONF_PATH="$_USERDIR/test.conf"

# Your MongoDB create Users Script
_MONGO_SCRIPT_PATH="$_USERDIR/mongo.js"

# :::::::::::::::::::::::::::::::::::: DO NOT EDIT BELOW THIS LINE  :::::::::::::::::::::::::::::::::::: 

# Add a user to Linux system
useradd -s /bin/bash -m -d $_USERDIR --user-group $_USERNAME
passwd $_USERNAME
echo "1. User $_USERNAME added successfully"

# As root, run this command to add your new user to the sudo group
gpasswd -a $_USERNAME sudo
echo "2. User granted sudo priviledges"

# Generate a Key Pair Locally (/Users/localuser/.ssh/id_rsa)
# ssh-keygen
# cat ~/.ssh/id_rsa.pub
# Add Public Key to New Remote User
# On the server, as the root user
mkdir -p $_USERDIR/.ssh
echo $_SSHkey >> $_USERDIR/.ssh/authorized_keys
chmod 600 $_USERDIR/.ssh/authorized_keys
chown $_USERNAME:$_USERNAME $_USERDIR/.ssh/authorized_keys
echo "3. Public key added successfully"

# Change Port & RootLogin
sed -i "s/Port 22/Port $_PORT/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

service ssh restart

echo "4. SSH configuration OK"

apt-get -y update && time sudo apt-get -y dist-upgrade
echo "5. Packages Upgraded"

apt-get -y install nginx
echo "6. Nginx Installed"

cp $_SITE_CONF_PATH /etc/nginx/sites-available/$_SITENAME
ln -s /etc/nginx/sites-available/$_SITENAME /etc/nginx/sites-enabled/$_SITENAME
service nginx restart
echo "7. Site Configured"

apt-get -y install curl
curl -sL https://deb.nodesource.com/setup | sudo bash -
apt-get install -y nodejs
npm install -g forever
echo "8. Node & Forever Installed"

# Install Mongo & create users
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get install -y mongodb-org
echo "9. Mongo Installed"
mongo $_MONGO_SCRIPT_PATH # or mongo < $_MONGO_SCRIPT_PATH
sed -i "s/#auth=true/auth=true/g" /etc/mongodb.conf
echo "10. Mongo Configured"

# Configure Upstart
cp $_UPSTART_CONF_PATH /etc/init/
echo "11. Upstart Script Copied!"
