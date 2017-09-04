#!/bin/bash
# Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
# GNU Affero General Public License v3.0

# mc.service.sh
# Shell script to create a Minecraft server daemon and a named pipe to send
# commands to Minecraft's console, also open firewall port with ufw.


# Requirements:   sudo apt-get -y install default-jre
# Change mode:    sudo chmod +x ./mc.service.sh
# Create:         sudo ./mc.service.sh
# Shutdown:       sudo systemctl stop minecraft.__YOUR_SERVER_NAME__.service
# Console input:  sudo bash -c 'echo __YOUR_COMMAND__ > ./__YOUR_SERVER_NAME__/fifo'
# Console output: tail -n +1 -f ./__YOUR_SERVER_NAME__/logs/latest.log

# ToDo: Find way to display console in real time instead of input/output
# ToDo: Install default-jre package if not installed
# ToDo: Allow to set basic properties by arguments

################################################################################
# Script properties
minecraftVersion="1.12.1" #="1.12.1"
allocatedRAM="1024M" #="1024M"
templateFolderName="_template" #="_template"

# Minecraft server properties if $serverName.properties file does not exist in template folder
max_tick_time="60000" #="60000"
generator_settings="" #=""
allow_nether="true" #="true"
force_gamemode="false" #="false"
gamemode="0" #="0"
enable_query="false" #="false"
player_idle_timeout="0" #="0"
difficulty="1" #="1"
spawn_monsters="true" #="true"
op_permission_level="4" #="4"
announce_player_achievements="true" #="true"
pvp="true" #="true"
snooper_enabled="true" #="true"
level_type="DEFAULT" #="DEFAULT"
hardcore="false" #="false"
enable_command_block="false" #="false"
max_players="20" #="20"
network_compression_threshold="256" #="256"
resource_pack_sha1="" #=""
max_world_size="29999984" #="29999984"
server_port="25566" #="25565"
server_ip="" #=""
spawn_npcs="true" #="true"
allow_flight="false" #="false"
level_name="world" #="world"
view_distance="10" #="10"
resource_pack="" #=""
spawn_animals="true" #="true"
white_list="false" #="false"
generate_structures="true" #="true"
online_mode="true" #="true"
max_build_height="256" #="256"
level_seed="" #=""
prevent_proxy_connections="false" #="false"
motd="A Minecraft Server" #="A Minecraft Server"
enable_rcon="false" #="false"
########################
# Internal variables
installFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
templateFolder=$installFolder$templateFolderName/

# ToDo: If default-jre is not installed, install it #dpkg -l default-jre

# If number of arguments recieved is not 2
if ([ $# != 2 ])
then
	# Number of arguments recieved is not 2
	
	# Display error message
	echo "ERROR number of arguments received must be 2, not "$#

	# Exit with error
	exit 1
fi

# If first argument is neither "create" nor "delete"
if ([ $1 != "create" ] && [ $1 != "delete" ])
then
	# First argument is neither "create" nor "delete"
	
	# Display error message
	echo "ERROR first argument must be either """create""" or """delete""""

	# Exit with error
	exit 1
fi

# If first argument is "create"
if ([ $1 == "create" ])
then
	# First argument is "create"
	
	# If second argument is a server name that already exists in installFolder
	if ([ -d $installFolder$2 ])
	then
		# Second argument is a server name that already exists in installFolder
	
		# Display error message
		echo "ERROR serverName $2 already in use by $installFolder$2/, cannot create"

		# Exit with error
		exit 1
	fi

	# Set server name
	serverName=$2

	# Internal variables
	serverpropertiesFile=$templateFolder$serverName".properties"

	# If there is a server.properties file to import
	if [ -f $serverpropertiesFile ]
	then
		# There is a server.properties file to import
		
		# Make information to display equal to the server.properties file path
		serverpropertiesFileDisplay=$serverpropertiesFile
	
		# Get the value of level-name from file
		level_name=$(grep -n "level-name=" $serverpropertiesFile)

		# Give to level_name the value from file
		level_name=${level_name:14}
	
		# Give to worldFolder the value from level_name
		worldFolder=$templateFolder$level_name/
	
		# If world folder does not exist
		if [ ! -d $worldFolder ]
		then
			# World folder does not exist
		
			# Give to worldFolder an empty value
			worldFolder=""
		fi
		
		# Make information to display equal to the worldFolder
		worldFolderDisplay=$worldFolder
	
	
	else
		# Make information to display empty
		serverpropertiesFileDisplay=""
		worldFolderDisplay=""
	fi

	# Get a list of all the sub folders*
	declare -a serverFolders=$(find $installFolder -maxdepth 1 -type d)

	# For each subfolder*
	for i in $serverFolders
	do 
		# *Only go ahead if not the first result of the array, which is the folder itself and not a sub folder, OR the template folder
		if [ "$i/" != "$templateFolder" ]
		then
			# Not the first result of the array
			
			# Get server port from server properties file
			inUse_serverPort=$(grep "server-port=" $i"/server.properties")
			
			# Only keep port number and add a space at the end
			inUse_serverPort=${inUse_serverPort:12:6}" "

			# Add server port to port string (ex: "25566 25567 25569 ")
			portString+=$inUse_serverPort
		fi
	done

	# While server port is in use by one of the current servers
	while ( echo $portString | grep $server_port > /dev/null 2>&1 )
	do
		# Server port is in use by one of the current servers

		# Increment server port
		server_port=$(($server_port + 1))
	done

	# Display instructions
	echo ""
	echo "########################"
	echo ""
	echo "  mc.service create"
	echo ""
	echo "########################"
	echo ""
	echo "         serverName: "$serverName
	echo "         serverPort: "$server_port
	echo "   minecraftVersion: "$minecraftVersion
	echo "       allocatedRAM: "$allocatedRAM
	echo "      installFolder: "$installFolder
	echo "     templateFolder: "$templateFolder
	echo "     propertiesFile: "$serverpropertiesFileDisplay
	echo "        worldFolder: "$worldFolderDisplay
	echo ""

	## If the script recieved the "-y" argument
	#if [ ""$1"" == "-y" ]
	#then
	#	# The script did recieve the "-y" argument
	#	
	#	# Give to keypress the value "-y"
	#	keypress=$1
	#	
	#	# Display instructions
	#	echo "  Continue? [Y/n]-y"
	#else
	#	# The script did not recieve the "-y" argument
	#	
		# Wait for keypress from user
		read -n1 -r -p "  Continue? [Y/n]" keypress
	#fi

	# If keypress was not either one of the Y, or y, or Enter key, or the flag -y
	if !([ "$keypress" == "Y" ] || [ "$keypress" == "y" ] || [ "$keypress" == "" ] || [ "$keypress" == "-y" ])
	then
		# Keypress was not either one of the Y, or y, or Enter key
	
		# If keypress was not Enter key
		if !([ "$keypress" == "" ])
		then
			# Add new line
			echo ""
		fi
	
		# End script
		exit 0
	fi

	# If keypress was either the Y, or y key
	if ([ "$keypress" == "Y" ] || [ "$keypress" == "y" ])
	then
		# Add new line
		echo ""
	fi
	keypress=/dev/null

	# Display instructions
	echo ""
	echo "  Wait time  1min (100% when done)"

	# If minecraft_server.jar of the requested version is not already downloaded in template folder
	if !([ -f $templateFolder"minecraft_server.$minecraftVersion.jar" ])
	then
		# Download minecraft_server.jar to install folder
		wget -P $templateFolder "https://s3.amazonaws.com/Minecraft.Download/versions/$minecraftVersion/minecraft_server.$minecraftVersion.jar" > /dev/null 2>&1
	fi

	# Create server folder
	mkdir $installFolder$serverName #> /dev/null 2>&1

	# Copy minecraft_server.jar in server folder
	cp $templateFolder"minecraft_server.$minecraftVersion.jar" $installFolder$serverName"/minecraft_server.jar"

	# If there is a server.properties file to import
	if [ -f $serverpropertiesFile ]
	then
		# There is a server.properties file to import
	
		# Copy server.properties in server folder
		cp $serverpropertiesFile $installFolder$serverName"/server.properties"
	
		# If there is a world folder to import
		if ([ -d $worldFolder ])
		then
			# There is a world folder to import
		
			# Copy world folder from template folder to server folder
			cp -r $worldFolder $installFolder$serverName/$level_name/
		fi
	else
		# There is no server.properties file to import
	
		# Create server.properties in server folder using provided minecraft server properties
		echo "#Minecraft server properties" > $installFolder$serverName"/server.properties"
		echo "#(File Modification Datestamp)" >> $installFolder$serverName"/server.properties"
		echo "max-tick-time="$max_tick_time >> $installFolder$serverName"/server.properties"
		echo "generator-settings="$generator_settings >> $installFolder$serverName"/server.properties"
		echo "allow-nether="$allow_nether >> $installFolder$serverName"/server.properties"
		echo "force-gamemode="$force_gamemode >> $installFolder$serverName"/server.properties"
		echo "gamemode="$gamemode >> $installFolder$serverName"/server.properties"
		echo "enable-query="$enable_query >> $installFolder$serverName"/server.properties"
		echo "player-idle-timeout="$player_idle_timeout >> $installFolder$serverName"/server.properties"
		echo "difficulty="$difficulty >> $installFolder$serverName"/server.properties"
		echo "spawn-monsters="$spawn_monsters >> $installFolder$serverName"/server.properties"
		echo "op-permission-level="$op_permission_level >> $installFolder$serverName"/server.properties"
		echo "announce-player-achievements="$announce_player_achievements >> $installFolder$serverName"/server.properties"
		echo "pvp="$pvp >> $installFolder$serverName"/server.properties"
		echo "snooper-enabled="$snooper_enabled >> $installFolder$serverName"/server.properties"
		echo "level-type="$level_type >> $installFolder$serverName"/server.properties"
		echo "hardcore="$hardcore >> $installFolder$serverName"/server.properties"
		echo "enable-command-block="$enable_command_block >> $installFolder$serverName"/server.properties"
		echo "max-players="$max_players >> $installFolder$serverName"/server.properties"
		echo "network-compression-threshold="$network_compression_threshold >> $installFolder$serverName"/server.properties"
		echo "resource-pack-sha1="$resource_pack_sha1 >> $installFolder$serverName"/server.properties"
		echo "max-world-size="$max_world_size >> $installFolder$serverName"/server.properties"
		echo "server-port="$server_port >> $installFolder$serverName"/server.properties"
		echo "server-ip="$server_ip >> $installFolder$serverName"/server.properties"
		echo "spawn-npcs="$spawn_npcs >> $installFolder$serverName"/server.properties"
		echo "allow-flight="$allow_flight >> $installFolder$serverName"/server.properties"
		echo "level-name="$level_name >> $installFolder$serverName"/server.properties"
		echo "view-distance="$view_distance >> $installFolder$serverName"/server.properties"
		echo "resource-pack="$resource_pack >> $installFolder$serverName"/server.properties"
		echo "spawn-animals="$spawn_animals >> $installFolder$serverName"/server.properties"
		echo "white-list="$white_list >> $installFolder$serverName"/server.properties"
		echo "generate-structures="$generate_structures >> $installFolder$serverName"/server.properties"
		echo "online-mode="$online_mode >> $installFolder$serverName"/server.properties"
		echo "max-build-height="$max_build_height >> $installFolder$serverName"/server.properties"
		echo "level-seed="$level_seed >> $installFolder$serverName"/server.properties"
		echo "prevent-proxy-connections="$prevent_proxy_connections >> $installFolder$serverName"/server.properties"
		echo "motd="$motd >> $installFolder$serverName"/server.properties"
		echo "enable-rcon="$enable_rcon >> $installFolder$serverName"/server.properties"
	fi

	# Create eula.txt in server folder to accept eula so server can initialize
	echo "eula=true" > $installFolder$serverName/eula.txt

	# Create named pipe in server folder to send commands to minecraft server process
	mkfifo $installFolder$serverName/fifo

	# Add exception to firewall to open server to Internet
	ufw allow $server_port > /dev/null 2>&1

	# Create systemd unit file using provided script properties
	echo "[Unit]" > /etc/systemd/system/minecraft.$serverName.service
	echo "Description=Minecraft Server $serverName" >> /etc/systemd/system/minecraft.$serverName.service
	echo "After=network.target" >> /etc/systemd/system/minecraft.$serverName.service
	echo "" >> /etc/systemd/system/minecraft.$serverName.service
	echo "[Service]" >> /etc/systemd/system/minecraft.$serverName.service
	echo "WorkingDirectory=$installFolder$serverName" >> /etc/systemd/system/minecraft.$serverName.service
	echo "ExecStart=/bin/bash -c 'tail -n +1 -f $installFolder$serverName/fifo | /usr/bin/java -Xms$allocatedRAM -Xmx$allocatedRAM -jar $installFolder$serverName/minecraft_server.jar nogui'" >> /etc/systemd/system/minecraft.$serverName.service
	echo "ExecStop=/bin/bash -c 'echo stop > $installFolder$serverName/fifo'" >> /etc/systemd/system/minecraft.$serverName.service
	echo "Restart=always" >> /etc/systemd/system/minecraft.$serverName.service
	echo "" >> /etc/systemd/system/minecraft.$serverName.service
	echo "[Install]" >> /etc/systemd/system/minecraft.$serverName.service
	echo "WantedBy=multi-user.target" >> /etc/systemd/system/minecraft.$serverName.service

	# Enable minecraft daemon
	systemctl enable minecraft.$serverName.service > /dev/null 2>&1

	# Start minecraft daemon
	systemctl start minecraft.$serverName.service

	# Display instructions
	echo ""
	echo "########################"
	echo ""
	echo "  Done"
	echo ""
	echo "########################"

fi

# If first argument is "delete"
if ([ $1 == "delete" ])
then
	# First argument is "delete"

	# If second argument is a server name that does not already exists in installFolder
	if (! [ -d $installFolder$2 ])
	then
		# Second argument is a server name that does not already exists in installFolder
		
		# Display error message
		echo "ERROR serverName $2 does not exists in $installFolder, cannot delete"

		# Exit with error
		exit 1
	fi

	# Set server name
	serverName=$2

	# Internal variables
	serverpropertiesFile=$installFolder$2"/server.properties"

	# Get the value of server-port from file
	server_port=$(grep -n "server-port=" $serverpropertiesFile)

	# Give to server_port the value from file
	server_port=${server_port:15}

	# Display instructions
	echo ""
	echo "########################"
	echo ""
	echo "  mc.service delete"
	echo ""
	echo "########################"
	echo ""
	echo "         serverName: "$serverName
	echo "         serverPort: "$server_port
	echo "   minecraftVersion: *ToDo" #$minecraftVersion
	echo "       allocatedRAM: *ToDo" #$allocatedRAM
	echo "      installFolder: "$installFolder
	echo ""

	## If the script recieved the "-y" argument
	#if [ ""$1"" == "-y" ]
	#then
	#	# The script did recieve the "-y" argument
	#	
	#	# Give to keypress the value "-y"
	#	keypress=$1
	#	
	#	# Display instructions
	#	echo "  Continue? [Y/n]-y"
	#else
	#	# The script did not recieve the "-y" argument
	#	
		# Wait for keypress from user
		read -n1 -r -p "  Continue? [Y/n]" keypress
	#fi

	# If keypress was not either one of the Y, or y, or Enter key, or the flag -y
	if !([ "$keypress" == "Y" ] || [ "$keypress" == "y" ] || [ "$keypress" == "" ] || [ "$keypress" == "-y" ])
	then
		# Keypress was not either one of the Y, or y, or Enter key
	
		# If keypress was not Enter key
		if !([ "$keypress" == "" ])
		then
			# Add new line
			echo ""
		fi
	
		# End script
		exit 0
	fi

	# If keypress was either the Y, or y key
	if ([ "$keypress" == "Y" ] || [ "$keypress" == "y" ])
	then
		# Add new line
		echo ""
	fi
	keypress=/dev/null

	# Display instructions
	echo ""
	echo "  Wait time  1min (100% when done)"

	# Stop daemon
	systemctl stop minecraft.$serverName.service

	# Disable daemon
	systemctl disable minecraft.$serverName.service > /dev/null 2>&1

	# Remove systemd unit file
	rm /etc/systemd/system/minecraft.$serverName.service

	# Remove server folder
	rm -r $installFolder$serverName/

	# Remove exception to firewall
	ufw delete allow $server_port > /dev/null 2>&1

	# Display instructions
	echo ""
	echo "########################"
	echo ""
	echo "  Done"
	echo ""
	echo "########################"
fi