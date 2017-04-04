#!/bin/bash
##raspi automagik digital signage script
##version .03c, written by Joseph Keller, 2017.
##run this app as root or with sudo privs!
##requires omxplayer and cifs-utils to work.

# USER CFG
configfile="./signage_script.cfg"
configfile_secure="/tmp/signage_script.cfg"

##checking that nobody has done anything funny to the config file
##thanks to the guy on the bash hackers wiki for this :)
if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
 	echo "Config file is unclean; cleaning..." >&2
	##clean config's contents and move to clean version
 	egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secure"
 	configfile="$configfile_secure"
fi

source $configfile

sudo rm $HOME/.smbcredentials
echo "username=$smbUser" >> $HOME/.smbcredentials
sed -i -e '$a\' $HOME/.smbcredentials
echo "password=$smbPass" >> $HOME/.smbcredentials
sudo chown root:root $HOME/.smbcredentials
sudo chmod 600 $HOME/.smbcredentials 

# HARDCODED VARIABLES
smbDisk="//${smbAddress}/${smbFilepath} $smbMountPoint cifs credenitals=$userHome/.smbcredentials,user 0 0"
ramDisk="tmpfs $ramDiskMountPoint tmpfs nodev,nosuid,size=$ramDiskSize 0 0"
scriptPID="cat /tmp/signage_script.pid"
remoteMD5Hash=`cat /dev/null | awk '{print $1}'`
localMD5Hash=`cat /dev/null | awk '{print $1}'`
tempLocalMD5Hash=`cat /dev/null | awk '{print $1}'`
tempLocal="${localFolder}/${signName}_temp.mp4"
echo "temporary local file name is $tempLocal"

# FUNCTIONS
function remoteFileCopy {
	sudo cp -p "${smbMountPoint}/${signName}.mp4" "${localFolder}/${signName}_temp.mp4" &
	wait $!
	tempLocalMD5Hash=`md5sum -b "${tempLocal}" | awk '{print $1}'` &
	wait $!
	echo "temporary local MD5 hash is $tempLocalMD5Hash"

	remoteMD5Length=${#remoteMD5Hash} ##should be 32, not zero

	if [ "$remoteMD5Length" == "0" ]; then ##sanity checking if server is offline
		echo -e "MD5 length is incorrect!\nis the file server offline?"
	elif [ "$tempLocalMD5Hash" == "$remoteMD5Hash" ]; then ##sanity checking to make sure the local file doesn’t get overwritten with something corrupt during transfer
		sudo cp -p "${localFolder}/${signName}_temp.mp4" "${localFolder}/${signName}.mp4" &
		wait $!
		localMD5Hash=`md5sum -b "${localFolder}/${signName}.mp4" | awk '{print $1}'` &
		wait $!
		echo “local MD5 hash is $localMD5Hash”
		sudo rm ${localFolder}/${signName}_temp.mp4
	else
		echo -e "local/remote checksum mismatch!\ndid you just update the remote file? otherwise, transfer corrupted!"
		sudo rm ${localFolder}/${signName}_temp.mp4
	fi
}

function ramFileCopy {
	if [ "$localMD5Hash" != "cat /dev/null | awk '{print $1}'" ]; then
		sudo cp -p "${localFolder}/${signName}.mp4" "${ramDiskMountPoint}/${signName}.mp4" &
	fi
}

function videoPlayer {
	sudo killall omxplayer
	omxplayer -b -o $audioOut --loop --no-osd --no-keys --orientation $screenOrientation --aspect-mode $aspectMode "${ramDiskMountPoint}/${signName}.mp4" & 
	##start omxplayer with a blanked background, output to hdmi, loop, turn off the on-screen display, and disable key controls
	sudo killall omxplayer.bin 
}

# MAIN PROGRAM

if ps --pid $scriptPID > /dev/null; then ##check if script is already running
	sudo kill $scriptPID
	if ps -p $scriptPID > /dev/null; then
		echo "No previous script running!"
	else
		echo "Previous script killed."
	fi
fi

if grep -q '$ramDisk' /etc/fstab; then
	sudo mkdir $ramDiskMountPoint
	sudo sed -i -e '$a\' /etc/fstab  && echo "$ramDisk" >> /etc/fstab ##copy new ramdisk mounting lines to fstab
	sudo mount -a
	if [ "$(ls -A ${ramDiskMountPoint})" ]; then ##check if the ram disk is mounted
		echo "ramdisk failed to mount!"
		exit
	else
		echo "ramdisk mounted."
	fi
else
	echo "fstab already updated with ramdisk"
fi

if grep -q '$smbDisk' /etc/fstab; then
	sudo mkdir $smbMountPoint
	sudo sed -i -e '$a\' /etc/fstab && echo "$smbDisk" >> /etc/fstab ##copy new smb mounting lines to fstab
	mount -a
	if [ "$(ls -A ${smbMountPoint})" ]; then
		echo "SMB mounted!"
		exit
	else
		echo "SMB failed to mount!"
		exit
	fi
else
	echo "fstab already updated with SMB"
fi

if [ "$(ls -A ${localFolder})" ]; then
	echo "Local folder already exists."
else
	sudo mkdir $localFolder
fi

sudo rm /tmp/signage_script.pid
sudo echo $BASHPID >> /tmp/signage_script.pid ##write out this script instance's PID to a file

##check for a local cached file and play that before moving on if it exists
ramFileCopy
wait $!
if [ "$(ls -A ${ramDiskMountPoint}/${signName}.mp4)" ]; then
	echo "Playing cached local file!"
	videoPlayer
fi

while true; do
	remoteMD5Hash=`md5sum -b "${smbMountPoint}/${signName}.mp4" | awk '{print $1}'` & ##update the remote file's MD5 hash every time the loop restarts
	wait $!
	echo "remote MD5 hash is: " $remoteMD5Hash
	if [ "$(ls -A ${localFolder}/${signName}.mp4)" ]; then ##do some sanity checking on the local file hash
		localMD5Hash=`md5sum -b "${localFolder}/${signName}.mp4" | awk '{print $1}'` &
		wait $!
	else
		localMD5Hash=0
	fi
	echo "local MD5 hash is: " $localMD5Hash

	if [ "$(ls -A ${ramDiskMountPoint}/${signName}.mp4)" ]; then ##check if the local file has been copied to RAM
		echo "Video file already in RAM!"
	else
		ramFileCopy
		wait $!
	fi

	if [ "$remoteMD5Hash" = /dev/null ] ; then ##if md5sum doesn't have a valid file to check, the MD5 sum variable ends up being null
		echo "No remote file found!"
		echo "Please check remote drive and/or configuration for errors!"
	elif [ "$remoteMD5Hash" != "$localMD5Hash" ]; then
		remoteFileCopy
		wait $!
		ramFileCopy
		wait $!
		videoPlayer
	fi

	sleep $checkInterval ##sleep the infinite loop for specified interval
done

