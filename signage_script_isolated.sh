#!/bin/bash
##isolated raspi automagik digital signage script
##version .01, written by Joseph Keller, 2017.
##run this app as root or with sudo privs!
##requires omxplayer, a full Rasbian installation, and rclone to work, though it should install rclone for you!

# USER CFG
configfile="./signage_script_isolated.cfg"
configfile_secure="/tmp/signage_script_isolated.cfg"

##checking that nobody has done anything funny to the config file
##thanks to the guy on the bash hackers wiki for this :)
if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
 	echo "Config file is unclean; cleaning..." >&2
	##clean config's contents and move to clean version
 	egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secured"
 	configfile="$configfile_secured"
fi

source $configfile

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
function ramFileCopy {
	if [ "$localMD5Hash" != "cat /dev/null | awk '{print $1}'" ]; then
		sudo cp -p "${localFolder}/${signName}.mp4" "${ramDiskMountPoint}/${signName}.mp4" &
	fi
}

function cloudSync {
    echo -e "\n\nnow checking for new files"
    time="/bin/date"

	if [ "rclone -q lsd $remoteDrive | grep $signName"
	    rclone -q sync $remoteDrive${$signName} $localFolder
        echo -e "$remoteDrive synced on $time"
    else
        echo -e "Does the directory $signName exist in $remoteDrive?/nIf not, please correct this.\n\nFiles not synced."
    fi
}

function videoPlayer {
	sudo killall omxplayer
	omxplayer -b -o hdmi --loop --no-osd --no-keys --orientation $screenOrientation --aspect-mode $aspectMode "${ramDiskMountPoint}/${signName}.mp4" & 
	##start omxplayer with a blanked background, output to hdmi, loop, turn off the on-screen display, and disable key controls
	sudo killall omxplayer.bin 
}

# MAIN PROGRAM
if [ "$(ls -A /usr/sbin/rclone)" ]; then
	echo "rclone already installed!"
else
	echo "installing rclone now"
	##download rclone
	curl -O http://downloads.rclone.org/rclone-current-linux-arm.zip
	unzip rclone-current-linux-arm.zip
	cd rclone-*-linux-arm

	##copy rclone and its manpage
	sudo cp rclone "/usr/sbin/"
	sudo chown root:root "/usr/sbin/rclone"
	sudo chmod 755 "/usr/sbin/rclone"
	sudo mkdir -p "/usr/local/share/man/man1"
	sudo cp rclone.1 "/usr/local/share/man/man1/"
	sudo mandb 
	
	echo "rclone now installed... opening configuration."
	rclone config
	wait $1
	echo -e "if using google drive, use your own client_id!\nfollow the instructions at the bottom of this page:\nhttps://rclone.org/drive/"
	sleep 5
	echo "cleaning up..."
	cd ..
	sudo rm -rf rclone-* ##this is dangerous, I know
fi

##setting the remote drive variable
##make sure the first drive you see in the output of 'rclone listremotes' is the one you want to use
remoteDrive=`rclone listremotes | awk 'NR == 1' $1`

if [ "rclone lsd $remoteDrive" ]; then 
	echo "rclone properly configured!"
else
	echo -e "please make sure rclone is configured and you're connected to the internet!\nrun 'rclone config' if you've verified internet connectivity"
	exit
fi

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
    ethStatus=`cat /sys/class/net/eth0/operstate`
	if [ $ethStatus = "down" ]; then
		echo "network connection is down! check the eth0 interface."
	elif [ "rclone -q ls $remoteDrive | echo $?" = 0 ]; then
		echo "internet connection is down! waiting $checkInterval seconds before trying again"
	else
		cloudSync
    fi

	if [ "$(ls -A ${ramDiskMountPoint}/${signName}.mp4)" ]; then ##check if the local file has been copied to RAM
		echo "Video file already in RAM!"
	else
		ramFileCopy
		wait $!
	fi

    videoPlayer

	sleep $checkInterval ##sleep the infinite loop for specified interval
done

