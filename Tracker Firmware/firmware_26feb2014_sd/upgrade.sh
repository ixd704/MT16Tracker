#!/bin/sh

FLASHCP=./flashcp
UBOOT=u-boot.bin
UIMAGE=uImage
ROOTFS=rootfs.cramfs


abort ()
{
	echo [FAILED]
	exit 1
}



verify()
{
	echo "Verifying MD5SUMs"
	md5sum -c md5sum.txt
	if [ $? -ne 0 ]; then
		echo "MD5 Verification failed!!"
		abort
	fi
}

flash_file()
{
	FILE=$1
	PARTITION=$2
	echo "Flashing '$FILE'.."
	$FLASHCP $FILE $PARTITION
	if [ $? -ne 0 ]; then
		echo "Flashing '$FILE' failed!!"
		abort
	fi
}


flash()
{
	echo Flashing will take some time. Please DO NOT interrupt the operation..
	flash_file $UIMAGE /dev/mtd1
	flash_file $ROOTFS /dev/mtd3
	flash_file $UBOOT /dev/mtd0
}


main()
{
	sync
	verify
	chmod +x $FLASHCP
	flash
	sync
	echo -e "\n\n[SUCCESS]"
	echo Please reboot the Tracker.
}



main

