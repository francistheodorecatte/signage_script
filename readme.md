# Raspberry Pi Signage Setup

Yeah, there's a bunch more options out there for this exact problem I'm solving; they just don't solve our needs. Also yeah, I know this is absolute amateur hour. 

## Client-side

The client-side script plays a looping video using omxplayer. Every minute, it checks for a newer version on an SMB server. If the version on the SMB server is newer than the cached local version, the script copies the newer file onto the SD card, and then into a RAM drive. Then it kills the video player and restarts it. 

It requires omxplayer and cifs-utils to work. If you want to keep your Pi from becoming part of a botnet, I suggest using ufw.

## Server-side

The server does a similar thing as the client side, checking for newer video versions on a Google Drive (or any other cloud storage setup rclone supports.) If there's a newer version, the script downloads it, automatically renames it if needed, and drops it into an SMB file share the server hosts.

This Pi requires a full Rasbian setup (not the lite distro), as well as rclone, to work.

## Disclaimers

If you copy this, god help you.

I wrote this to meet our specific needs for a specific project. As of this writing, using it outside of that specific use-case is at your own risk. Do not expect any support from me in using it.

Happy hacking!
