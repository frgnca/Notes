#!/bin/bash
# Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
# GNU Affero General Public License v3.0

# setupTemplate.sh
# Shell script that modifies basic Ubuntu Server 16.04.02 template


################################################################################
# Set new configuration
newUser="test"
newHostname="test01"
newIP="192.168.1.31"
########################
# Set internal variables
templateUser="user"
templateHostname="computer"
templateIP="192.168.1.100"

# Create new user
adduser $newUser
usermod -aG sudo $newUser

# Bring up to date
apt-get update && apt-get -y upgrade

# Create shell script to remove template user and script call from /etc/rc.local
echo "#!/bin/bash" > removeTemplateUser.sh
echo "# Copyright (c) 2017 Francois Gendron <fg@frgn.ca>" >> removeTemplateUser.sh
echo "# GNU Affero General Public License v3.0" >> removeTemplateUser.sh
echo "" >> removeTemplateUser.sh
echo "# removeTemplateUser.sh" >> removeTemplateUser.sh
echo "# Shell script that removes template user and a call to itself in /etc/rc.local" >> removeTemplateUser.sh
echo "" >> removeTemplateUser.sh
echo "" >> removeTemplateUser.sh
echo "################################################################################"	>> removeTemplateUser.sh
echo "templateUser=\"user\"" >> removeTemplateUser.sh
echo "########################" >> removeTemplateUser.sh
echo "# Remove template user" >> removeTemplateUser.sh
echo "userdel -r \$templateUser" >> removeTemplateUser.sh
echo "" >> removeTemplateUser.sh
echo "# Remove script call from /etc/rc.local" >> removeTemplateUser.sh
echo "exit0=\"exit 0\"" >> removeTemplateUser.sh
echo "scriptCall=\"/home/user/./removeTemplateUser.sh\"" >> removeTemplateUser.sh
echo "sed -i \"s#\$scriptCall#\$exit0#\" /etc/rc.local" >> removeTemplateUser.sh

# Make script executable
chmod +x removeTemplateUser.sh

# Call script from /etc/rc.local on next boot
exit0="exit 0"
scriptCall="/home/user/./removeTemplateUser.sh"
sed -i "s#$exit0#$scriptCall#" /etc/rc.local

# Change static IP
sed -i "s/$templateIP/$newIP/" /etc/network/interfaces
sed -i "s/$templateIP/$newIP/" /etc/hosts

# Change hostname
sed -i "s/$templateHostname/$newHostname/" /etc/hostname
sed -i "s/$templateHostname/$newHostname/" /etc/hosts

# Reboot
reboot
