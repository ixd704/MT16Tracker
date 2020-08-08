# MT16Tracker
JamHub open source files for the MT16Tracker.

Steve Skillings (steve.skillings@jamhub.com) has asked that source code be released for the MT16Tracker.  I have an email from Steve stating, "All of the software can go on GitHub.  No worries about the license." So you are free to do as you wish with it.

To date I have:
- cracked the root password which is P0o9i8u7
- a ROM image which can be disected by those interested in seeing how it works.
- the Linux code I created based on the Windows version of the product being run through IDA Pro which includes a modified version of sndlib-deinterleave by Erik de Castro Lopo and his license to use it.
- the schematic for the JamHub remote that will give you the cable connections.
- there are a number of MT16 Trackers available for for a small fee (I am currently unsure as to what the fee is) and shipping costs for those developers wishing to have a MT16 Tracker to work with.  You will need to contact Steve to request one be sent to you.  

You will require sndlib and GTK3 to be installed on Linux to compile the code.   Anyone wishing to contribute can join the effort.

Some info on the MT16Tracker:
- it runs a telnet server with the user account being set to user and the password also set to user.
- if you unzip the ROM to a directory called firmware_26feb2014_sd on the sd card, it will load the firmware on boot if you place the autostart.sh script in the root directory of the SD Card.  The init script will check for the autostart.sh file during boot.  Reboot the Tracker and you will have the ROM version installed.   Version 1.0 has no root password, so easy to su to root account.  

***NOTE*** firmware_26feb2014_sd is version 1.0.  
***NOTE*** I managed to brick a device trying to rebuild the rootfs.cramfs file with a new shadow file.   I expect u-boot is required to make changes so that the image files fit into the file system correctly.  Hopefully a build source tree will show up soon.
