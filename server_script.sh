#!/bin/bash
##Server Script companion for the Rasberry Pi digital signage script.
##Version .01 by Joseph Keller, 2016
##Pulls videos for display down from Google Drive, automatically renames them, and puts them in an SMB file share.
##Requires a full Rasbian installation and rclone to work

if [ "$(ls -A /usr/sbin/rclone" ]; then
	echo "rclone already installed!"
else
	echo "installing rclone now"
	##download rclone
	curl -O http://downloads.rclone.org/rclone-current-linux-amd64.zip &
	wait $!
	unzip rclone-current-linux-amd64.zip &
	wait $!
	cd rclone-*-linux-amd64

	##copy rclone and its manpage
	sudo cp rclone /usr/sbin/
	sudo chown root:root /usr/sbin/rclone
	sudo chmod 755 /usr/sbin/rclone
	sudo mkdir -p /usr/local/share/man/man1
	sudo cp rclone.1 /usr/local/share/man/man1/
	sudo mandb 
	
	echo "rclone now installed"
fi

if [ "check for configured rclone returns true" ]; then
	echo "rclone already configured!"
else
	rclone config
fi
