#!/bin/bash
##Server Script companion for the Rasberry Pi digital signage script.
##Version .01 by Joseph Keller, 2016
##Pulls videos for display down from Google Drive, automatically renames them, and puts them in an SMB file share.
##Requires a full Rasbian installation and rclone to work

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
	sudo cp rclone /usr/sbin/
	sudo chown root:root /usr/sbin/rclone
	sudo chmod 755 /usr/sbin/rclone
	sudo mkdir -p /usr/local/share/man/man1
	sudo cp rclone.1 /usr/local/share/man/man1/
	sudo mandb 
	
	echo "rclone now installed... opening configuration."
	rclone config &
	wait $!
	echo -e "if using google drive, use your own client_id!\nfollow the instructions at the bottom of this page:\nhttps://rclone.org/drive/"
	wait 5
fi

##setting the remote drive variable
##make sure the first drive you see in the output of 'rclone listremotes' is the one you want to use
remoteDrive = `rclone listremotes | awk 'NR == 1' $1`

if [ "rclone lsd $remoteDrive" ]; then 
	echo "rclone properly configured!"
else
	echo -e "please make sure rclone is configured and you're connected to the internet!\nrun 'rclone config' if you've verified internet connectivity"
	exit
fi

##setup SMB

if [ "no smb setup" ]; then
	echo "no samba server found!"

	##make sure samba is installed
	sudo apt-get install samba samba-common-bin 

	##add some stuff to the smb config
	echo -e "\nworkgroup = $workgroup" >> /etc/samba/smb.conf
	echo -e "\nwins support = yes" >> etc/samba/smb.conf
	echo -e "\n\n[signageServer]\n   comment=signage server\n   path=$smbPath\n   browseable=Yes\n   writeable=no\n   only guest=no\n   create mask=0777\n   directory mask=0777\n   public=no"
	
	echo "Now enter your user's password twice and the smb server will be configured"
	smbpasswd -a $USER
fi

##main loop

##fi



