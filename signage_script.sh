#!/bin/bash
##raspi automagik digital signage script
##version .02, written by Joseph Keller, 2016.
##run this app as root or with sudo privs!
##requires omxplayer,pqiv and cifs-utils to work.

##USER CFG
configfile="./signage_script.cfg"
configfile_secure="/tmp/signage_script.cfg"

if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
 	echo "Config file is unclean; cleaning..." >&2
	##clean config's contents and move to clean version
 	egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secured"
 	configfile="$configfile_secured"
fi

source $configfile

rm $userHome/.smbcredentials
echo "username=$smbUser" >> $userHome/.smbcredentials
sed -i -e '$a\' $HOME/.smbcredentials
echo "password=$smbPass" >> $userHome/.smbcredentials

##HARDCODED VARIABLES
smbDisk="//${smbAddress}/${smbFilepath} $smbMountPoint cifs credenitals=$userHome/.smbcredentials,user 0 0"
ramDisk="tmpfs $ramDiskMountPoint tmpfs nodev,nosuid,size=$ramDiskSize 0 0"
remoteFileTime=0
localFileTime=0
currentTime=0
scriptPID="cat /tmp/signage_script.pid"

##FUNCTIONS
function remoteFileCopy {
	cp -p "${smbMountPoint}/${signName}.mp4" "${localFolder}/${signName}.mp4" & 
	localFileTime='stat -c %Y "${local_folder}/${sign_name}.mp4"'
}

function ramFileCopy {
	cp -p "${localFolder}/${signName}.mp4" "${ramDiskMountPoint}/${signName}.mp4" & 
}

function videoPlayer {
	killall omxplayer 
	killall pqiv 
	omxplayer -o hdmi --loop --no-osd --no-keys "${ramDiskMountPoint}/${signName}.mp4" & 
}

#function log() {
#	#ONLY USE THIS FOR DEBUGGING
#	#WILL CAUSE WAY TOO MANY UNNECESSARY FLASH WRITES!
#	#(if it works)
#
#	currentTime=$(date '+%d/%m/%Y %H:%M:%S'); ##gets current day, month, year, hour, minute and second
#	echo $currentTime >> ${local_folder}/${sign_name}_log.txt
#	echo $1 &> ${local_folder}/${sign_name}_log.txt #pipes the redirected stdout/stderr to the log
#	#NOT SURE IF THIS IS GONNA WORK LOL
#	#abusing pipes and redirects like this is something I've never tried
#
#	sed -i -e '$a\' ${local_folder}/$sign_name}log.txt ##adding a new line to the log
#
#}

##MAIN PROGRAM
if ps --pid $scriptPID > /dev/null; then ##check if script is already running
	kill $scriptPID
	if ps -p $scriptPID > /dev/null; then
		echo "No previous script running!" 
	else
		echo "Previous script killed." 
	fi
fi

if grep -q '$ramDisk' /etc/fstab; then 
	mkdir $ramDiskMountPoint
	sed -i -e '$a\' /etc/fstab  && echo "$ramDisk" >> /etc/fstab ##copy new ramdisk mounting lines to fstab
	mount -a
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
	mkdir $smbMountPoint
	sed -i -e '$a\' /etc/fstab && echo "$smbDisk" >> /etc/fstab ##copy new smb mounting lines to fstab
	mount -a
	if [ "$(ls -A ${smbMountPoint})" ]; then
		echo "SMB mounted!" 
		exit
	else
		echo "SMB failed to mount!"
		exit
	fi
else
	echo "fstab already updated with smb" 
fi

if [ "$(ls -A ${smbMountPoint})" ]; then
	mkdir $localFolder
fi

rm /tmp/signage_script.pid
echo $BASHPID >> /tmp/signage_script.pid ##write out this script instance's PID to a file

while :
do
	remoteFileTime='stat -c %Y ${smbMountPoint}/${sign_name}.mp4' ##update the remote file MTIME every time the loop restarts
	if [ "$(ls -A ${ramDiskMountPoint}/${signName}.mp4)" ]; then ##check if the local file has been copied to RAM
		ramFileCopy
		wait ${!}
	fi

	if [ "$(ls -A  ${ramDiskMountPoint}/${signName}.mp4)" ]; then ##check if the video file is in RAM
		if "$(ls -A ${smbMountPoint/${signLogo})" ]; then
			echo "No video or logo to display found."  ##complain that we have nothing to do
		else
			echo "No video to display found."
			pqiv --fullscreen ${smbMountPoint}/${signLogo}  ##display the logo while we wait for the video to appear
		fi
	fi

	if remoteFileTime>=localFileTime; then
		remoteFileCopy
		wait ${!}
		killall omxplayer
		killall pqiv
		pqiv --fullscreen ${smbMountPoint}/${signLogo} &  ##display fullscreen image while the player refreshes
		ramFileCopy
		wait ${!}
		videoPlayer
	else
		killall omxplayer
		videoPlayer
	fi

	sleep 1m ##sleep the infinite loop for one minute
done
