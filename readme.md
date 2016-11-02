Raspberry Pi Signage Scipt v0.1c

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour.

Right now you need to edit the variables in the script directly to change directories and such. I'll move this to a .config file eventually to make setup easier.

Requires omxplayer, pqiv, and cifs-utils to work.

If you copy this code, god help you.

Initial setup:
-change raspbian hostname
-passwd
-sudo ufw default deny
sudo ufw allow ssh
sudo ufw allow http
sudo ufs allow https
sudo ufw allow proto udp from 192.168.x.0/24 to any port 137
sudo ufw allow proto udp from 192.168.x.0/24 to any port 138
sudo ufw allow proto tcp from 192.168.x.0/24 to any port 139
sudo ufw allow proto tcp from 192.168.x.0/24 to any port 445  
sudo ufw enable
-setup auto login to terminal prompt
-add script to profile autorun
-change script variables as needed
-reboot

Subsequent setup:
-ctrl+c to break out of script
-change hostname
-reboot
