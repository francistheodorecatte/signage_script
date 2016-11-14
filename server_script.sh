#!/bin/bash
##Server Script companion for the Rasberry Pi digital signage script.
##Version .01 by Joseph Keller, 2016
##Pulls videos for display down from Google Drive (or any other cloud storage rclone supports,) automatically renames them, and puts them in an SMB file share.
##Requires a full Rasbian installation and rclone to work, though it should install rclone for you!

# USER CONFIG
configfile="./server_script.cfg"
configfile_secure="/tmp/server_script.cfg"

##checking that nobody has done anything funny to the config file
##thanks to the guy on the bash hackers wiki for this :)
if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
 	echo "Config file is unclean; cleaning..." >&2
	##clean config's contents and move to clean version
 	egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secured"
 	configfile="$configfile_secured"
fi

source $configfile

# MAIN PROGRAM
if [ "$(ls -A /usr/sbin/rclone" ]; then
	echo "rclone already installed!"
else
	echo "installing rclone now"
	##download rclone
	curl -O http://downloads.rclone.org/rclone-current-linux-amd64.zip
	unzip rclone-current-linux-amd64.zip
	cd rclone-*-linux-amd64

	##copy rclone and its manpage
	sudo cp rclone "/usr/sbin/"
	sudo chown root:root "/usr/sbin/rclone"
	sudo chmod 755 "/usr/sbin/rclone"
	sudo mkdir -p "/usr/local/share/man/man1"
	sudo cp rclone.1 "/usr/local/share/man/man1/"
	sudo mandb 
	
	echo "rclone now installed... opening configuration."
	rclone config &
	wait $!
	echo -e "if using google drive, use your own client_id!\nfollow the instructions at the bottom of this page:\nhttps://rclone.org/drive/ "
	wait 5
fi

exit
