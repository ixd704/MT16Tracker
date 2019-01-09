# MT16Tracker
JamHub open source files for the MT16Tracker.

Steve Skillings has asked that source code be released for the MT16Tracker.  I have an email from Steve stating, "All of the software can go on GitHub.  No worries about the license." So you are free to do as you wish with it.

To date I have:
- a ROM image which can be disected by those interested in seeing how it works.
- the Linux code I created based on the Windows version of the product being run through IDA Pro which includes a modified version of sndlib-deinterleave by Erik de Castro Lopo and his license to use it.
- the schematic for the JamHub remote that will give you the cable connections.
- there are a number of MT16 Trackers available for for a small fee (I am currently unsure as to what the fee is) and shipping costs for those developers wishing to have a MT16 Tracker to work with.  You will need to contact Steve to request one be sent to you.  His contact information is in the source.

You will require sndlib and GTK3 to be installed on Linux to compile the code.   Anyone wishing to contribute can join the effort.

Some info on the MT16Tracker:
- it runs a telnet server with the user account being set to user and the password also set to user.
- if you unzip the ROM to a directory called update on the sd card, it will load the firmware on boot.
