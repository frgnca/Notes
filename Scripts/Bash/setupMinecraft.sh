#!/bin/bash
# Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
# GNU Affero General Public License v3.0

# setupMinecraft.sh
# Shell script that installs a minecraft server


################################################################################
# Copy files from host to VM
########################
# Display instructions
echo ""
echo "########################"
echo ""
echo "  setupMinecraft"
echo ""
echo "########################"
echo ""
echo "Wait time 10min (100% when done)"
echo ""

# Fix apt-get problem from template
rm -f /var/lib/dpkg/lock > /dev/null 2>&1
dpkg --configure -a > /dev/null 2>&1

# Bring system up to date
apt-get update > /dev/null 2>&1
apt-get -y upgrade > /dev/null 2>&1

# Install Java Runtime Environment
apt-get -y install default-jre > /dev/null 2>&1

# Create named pipes to send commands to minecraft server process
mkfifo /home/mc/MontLyallSurvival/fifo > /dev/null 2>&1
mkfifo /home/mc/MontLyallCreative/fifo > /dev/null 2>&1
mkfifo /home/mc/MontLyallAdventure/fifo > /dev/null 2>&1

# Make scripts executable
chmod +x /home/mc/snapshotCtoA.sh > /dev/null 2>&1
chmod +x /home/mc/MontLyallSurvival/1minWarningBeforeStop.sh > /dev/null 2>&1
chmod +x /home/mc/MontLyallCreative/1minWarningBeforeStop.sh > /dev/null 2>&1
chmod +x /home/mc/MontLyallAdventure/1minWarningBeforeStop.sh > /dev/null 2>&1

# Copy crontab file
crontab /home/mc/crontabFile.sh > /dev/null 2>&1

# Add exception to firewall to open servers to Internet
ufw allow 25565 > /dev/null 2>&1
ufw allow 25566 > /dev/null 2>&1
ufw allow 25567 > /dev/null 2>&1

# Enable minecraft daemons
systemctl enable minecraft_montlyall_survival.service > /dev/null 2>&1
systemctl enable minecraft_montlyall_creative.service > /dev/null 2>&1
systemctl enable minecraft_montlyall_adventure.service > /dev/null 2>&1

# Start minecraft daemons
systemctl start minecraft_montlyall_survival.service > /dev/null 2>&1
systemctl start minecraft_montlyall_creative.service > /dev/null 2>&1
systemctl start minecraft_montlyall_adventure.service > /dev/null 2>&1

# Delete files needed only for initial setup
rm -f /home/mc/crontabFile.sh > /dev/null 2>&1
rm -f /home/mc/setup_Minecraft.sh > /dev/null 2>&1

# Display instructions
echo "########################"
echo ""
echo "Done"
echo ""
echo "########################"