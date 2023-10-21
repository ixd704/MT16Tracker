# MT16Tracker
JamHub open source files for the MT16Tracker.

Steve Skillings (steve.skillings@jamhub.com) has asked that source code be released for the MT16Tracker.  I have an email from Steve stating, "All of the software can go on GitHub.  No worries about the license." So you are free to do as you wish with it.  Unfortunately the source was never given to JamHub as they out sourced the work and never got a valid copy from the sub contractor, so this is now a reverse engineering exersize...

To date I have:
- cracked the root password which is P0o9i8u7
- a ROM image which can be disected by those interested in seeing how it works.
- the Linux code I created based on the Windows version of the product being run through IDA Pro which includes a modified version of sndlib-deinterleave by Erik de Castro Lopo and his license to use it.
- the schematic for the JamHub remote that will give you the cable connections.
- there are a number of MT16 Trackers available for for a small fee (I am currently unsure as to what the fee is) and shipping costs for those developers wishing to have a MT16 Tracker to work with.  You will need to contact Steve to request one be sent to you.  He would prefer that the units he still has sitting on the shelf go to people wanting to tinker than go into a ground fill.  It is a pretty good deal.  You get a recording unit that can record 16 tracks at a time and also has a load of other features on the chipset.

There is a virtual machine image available here that will allow you to compile your code to run on it:
https://mega.nz/file/nYwzEAbC#bXCHMGGdTuczqBc49LXcGFnkZ_bV5l5mkDCCcxLkXP8
I have set the password to P@ssw0rd1.  Just cd to ltib and then build what you want with ./ltib -m scbuild -p menu as an example of building the menu program.

A zip file with firmware 3.0.2 is available from here:
https://drive.google.com/file/d/1Lm_nwLn0YRyLtSZ8Ez4GQEZlEfac7Z5K/view?usp=share_link

A bad video (rushed) of me updating the firmware is available here:
https://drive.google.com/file/d/1D8XaW71mvEOWE1MgDB10yFlL2UnbGrcq/view?usp=sharing

You will require sndlib and GTK3 to be installed on Linux to compile the code.   Anyone wishing to contribute, can.

Some info on the MT16Tracker:
- it runs a telnet server with the user account being set to user and the password also set to user.  You can su to root or login with root and P0o9i8u7.
 

***NOTE*** firmware_26feb2014_sd is version 1.0.  
***NOTE*** I managed to brick a device trying to rebuild the rootfs.cramfs file with a new shadow file.  So compiling new firmware is required for persistant changes.  Although, it is possible to plug in a USB drive and then use a start shell script from the SDCard to mount your own directories and software for use.  So a VST plugin is possible to create for it.  For $50 I doubt you will be able to find a 16 track recorder anywhere else...
