# Raspberry Pi Signage Script v0.1c

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour.

Right now you need to edit the variables in the script directly to change directories and such. I'll move this to a .config file eventually to make setup easier.

Requires omxplayer, pqiv, and cifs-utils to work.

If you copy this code, god help you.

##Initial setup
1. change raspbian hostname
2. passwd
3. setup wifi
4. disable USB auto mounting
5. sudo apt-get install -y omxplayer pqiv cifs-utils 
6. sudo ufw default deny
7. sudo ufw allow ssh
8. sudo ufw allow http
9. sudo ufs allow https
10. sudo ufw allow samba
11. sudo ufw enable
12. setup auto login to terminal prompt
13. add script to profile autorun
14. change script variables as needed
15. reboot

##Subsequent setup:
1. ctrl+c to break out of script
2. change hostname
3. reboot
