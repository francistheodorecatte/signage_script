# Raspberry Pi Signage Script v0.2

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour. 

Basically, this script plays a looping video using omxplayer. Every minute, it checks for a newer version on an SMB server. If the version on the SMB server is newer than the cached local version, the script copies the newer file onto the SD card, and then into a RAM drive. Then it kills the video player and restarts it. 

Now including a user config file with some simple input sanitization!

Requires omxplayer and cifs-utils to work. If you want to keep your Pi from becoming part of a botnet, I suggest using ufw.

If you copy this code, god help you
