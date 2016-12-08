# Raspberry Pi Signage Setup

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour. 

## Client-side

The client-side script plays a looping video using omxplayer. Every minute, it checks for a newer version on an SMB server. If the version on the SMB server is newer than the cached local version, the script copies the newer file onto the SD card, and then into a RAM drive. Then it kills the video player and restarts it. 

It requires omxplayer and cifs-utils to work. If you want to keep your Pi from becoming part of a botnet, I suggest using ufw.

## Server-side

The server does a similar thing as the client side, checking for newer video versions on a Google Drive (or any other cloud storage setup rclone supports.) If there's a newer version, the script downloads it, automatically renames it if needed, and drops it into an SMB file share the server hosts.

This Pi requires a full Rasbian setup (not the lite distro), as well as rclone, to work. However, the script will install and configure rclone with only a little user interaction. :)

As of now, December 8th, 2016, the server-side script is far from finished. It 'works,' but I wouldn't recommend using it unless you know bash scripting really well. We're currently just using a manually updated smb server instead. We probably won't use and therefore bugfix this script until we actually put it into use.

As a result, I don't recommend using it! 

## Disclaimers

If you copy this, god help you.

I wrote this to meet our specific needs for a specific project. As of this writing, using it outside of that specific use-case is at your own risk. Do not expect any support from me in using it.

If you have more than 5-10 Pi's running this script on a wireless network, increase the checkInterval value in signage_script.cfg to a large value, like 3600 (1 hour.) Otherwise you'll wreck your network!

Happy hacking!
