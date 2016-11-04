# Raspberry Pi Signage Script v0.2

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour.

Now including a user config file with some simple input sanitization! Fancy.

Requires omxplayer, pqiv, and cifs-utils to work. If you want to keep your Pi from becoming part of a botnet, I suggest using ufw.

If you copy this code, god help you.

##Initial setup
1. change raspbian hostname
2. passwd
3. setup wifi
4. disable USB auto mounting
5. sudo apt-get install -y omxplayer pqiv cifs-utils git 
6. sudo ufw default deny
7. sudo ufw allow from 192.168.x.0/24
8. sudo ufw allow ssh
9. sudo ufw allow http
10. sudo ufs allow https
11. sudo ufw allow samba
12. sudo ufw enable
13. setup auto login to terminal prompt
14. add script to profile autorun
15. change script variables as needed
16. reboot

##Subsequent setup:
1. ctrl+c to break out of script
2. change hostname
3. reboot
