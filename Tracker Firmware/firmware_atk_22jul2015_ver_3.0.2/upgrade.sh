#!/bin/sh

CHROOT_DIR=/dev/shm/firmware
SCRIPT_NAME=$(basename $0)
SCRIPT_PATH=$PWD
UPGRADING=0

FLASHCP=./flashcp
FW_SETENV=./fw_setenv
FW_PRINTENV=fw_printenv
LCDC=./lcdc
FLASHMON=./flashmon
UBOOT=u-boot.bin
UIMAGE=uImage
ROOTFS=rootfs.cramfs
VERSION_FILE=version
BL_VERSION_FILE=bl_version

MSG_NO_RESTART="DO NOT RESTART"

abort ()
{
	echo [FAILED]
	$LCDC -c1 -1'PLEASE RESTART'
	exit 1
}

runtime_error ()
{
	local ERROR_CODE=$1
	echo  "RT ERROR:$ERROR_CODE, $2"
	$LCDC -c2 -2"RT ERROR:$ERROR_CODE"
	abort
}

verify()
{
	echo "Verifying MD5SUMs"
	$LCDC -c2 -2'Verifying MD5'
	md5sum -c md5sum.txt
	if [ $? -ne 0 ]; then
		echo "MD5 Verification failed!!"
		$LCDC -c2 -2'MD5 Error'
		abort
	fi
}

flash_file()
{
	FILE=$1
	PARTITION=$2
	LABEL=$3
	echo "Flashing '$FILE'.."
	$FLASHCP -v $FILE $PARTITION | tr '\r' '\n' | $FLASHMON -l$LABEL
	if [ $? -ne 0 ]; then
		echo "Flashing '$FILE' failed!!"
		$LCDC -c2 -2"$LABEL Failed"
		abort
	fi
}

remount()
{
	echo $BASE_MOUNT_DIR | grep /mnt > /dev/null
	if [ $? -eq 0 ]; then
		echo Remounting $BASE_MOUNT_DIR in R/W mode
		mount -oremount,rw $BASE_MOUNT_DIR
	fi	
}

flash()
{
	flash_file $UIMAGE /dev/mtd1 Kernel
	flash_file $ROOTFS /dev/mtd3 RootFS

	if [ "x$bl_version" != "x" ]; then
		flash_file $UBOOT /dev/mtd0 UBoot
	fi
}

load_version()
{
	if [ -e $VERSION_FILE ]; then
		version=$(cat $VERSION_FILE)
		if [ "x$version" != "x" ]; then
			echo Flashing Firmware $version
		fi
	fi

	bl_version=$(cat $BL_VERSION_FILE 2>/dev/null)
	if [ "x$bl_version" == "x" ]; then
		bl_version=1
	fi


	lbl_version=$($FW_PRINTENV -l -n bl_version)
	if [ "x$bl_version" == "x$lbl_version" ]; then
		unset bl_version
	fi
	unset lbl_version
}

save_version()
{
	$LCDC -c2 -2"Saving Version"
	if [ "x$version" != "x" ]; then
		echo Updating Firmware version
		$FW_SETENV -l fw_version "$version"
	fi

	if [ "x$bl_version" != "x" ]; then
		echo Updating Boot Loader version
		$FW_SETENV -l bl_version "$bl_version"
	fi
}



do_sanity_check()
{
	echo Upgrading Firmware
	echo -e "Please DO NOT disturb the system (such as executing commands over Telnet OR thru Menu)!!\n"
	sync
	verify
	remount
	chmod +x *

}

do_upgrade()
{
	load_version
	flash
	save_version
	echo -e "\n\n[SUCCESS]"
	echo Please restart the Tracker.
	$LCDC -c1 -c2 -1"SUCCESS" -2"PLEASE REBOOT"
}

##CHROOT Functions
copy_chroot_file()
{
	if [ $# -lt 2 ]; then
		runtime_error 1 "Invalid syntax"
	else 
		eval TARGET=\${$#}
		let ARG_COUNT=$#
		i=1
		while  [ 1 ]; do
			eval SRC=\${$i}
#			echo copy "$SRC -> $TARGET"
			cp -a "$SRC" "$TARGET"
			if [ $? -ne 0 ]; then
				runtime_error 2 "Unable to copy $SRC"
			fi
			i=`expr $i + 1`
			if [ $i -eq $ARG_COUNT ]; then
				break
			fi
		done
	fi
}



prepare_chroot_fs()
{
	copy_chroot_file /bin/busybox $CHROOT_DIR/bin/
	copy_chroot_file /lib/libc.so.6 $CHROOT_DIR/lib/
	copy_chroot_file /lib/libc-2.5.so $CHROOT_DIR/lib/
	copy_chroot_file /lib/ld-2.5.so $CHROOT_DIR/lib/
	copy_chroot_file /lib/ld-linux.so.3 $CHROOT_DIR/lib/

	for target in $BUSYBOX_BINS; do
		ln -sf /bin/busybox $CHROOT_DIR/bin/$target
		if [ $? -ne 0 ]; then
			runtime_error 3 "Unable to create $target"
		fi
	done
	ln -sf $SCRIPT_PATH/`basename $FW_SETENV` $CHROOT_DIR/bin/$FW_PRINTENV
}


rebind_dirs()
{
	for dir in $REBIND_DIRS; do
		if [ -d "/$dir" ]; then
			mount -obind "/$dir" "$CHROOT_DIR/$dir"
			if [ $? -ne 0 ]; then
				runtime_error 4 "Unable bind $dir"
			fi
		fi
	done

}

unbind_dirs()
{
	cd /
	for dir in $REBIND_DIRS; do
		umount "$dir" 2> /dev/null
	done
}

do_reboot()
{
	echo "----Rebooting----"
	$LCDC -c2 -2"REBOOTING.."
	sleep 3
	echo u > /proc/sysrq-trigger
	echo b > /proc/sysrq-trigger
	
}

make_chroot_dir()
{
	if [ $# -ne 1 ]; then
		runtime_error 5 "Invalid syntax"
	else 
		mkdir -p "$1"
		if [ $? -ne 0 ]; then
			runtime_error 6 "Unable to create $1"
		fi
	fi
}


make_fs_dirs()
{
	if [ -d $CHROOT_DIR ]; then
		runtime_error 7 "Upgrade directory '$CHROOT_DIR' already exists, aborting"
	fi

	if [ "x$BASE_MOUNT_DIR" == "x/" ]; then
		runtime_error 8 "Can't operate from RootFS"
	fi


	make_chroot_dir $CHROOT_DIR
	for dir in $FS_DIRS; do
		make_chroot_dir $CHROOT_DIR/$dir
	done
}

rebase()
{
	make_fs_dirs
	prepare_chroot_fs
	rebind_dirs
}

setup_environment()
{
SCRIPT_REL_PATH=$(echo $SCRIPT_PATH | sed 's/^\/\(.*\)/\1/')
BASE_MOUNT_DIR=$(df "$PWD" | tail -1 | sed -n 's/  */#/gp' | cut -d '#' -f 6)
FS_DIRS="bin dev dev/pts dev/shm etc lib mnt  proc sbin sys tmp $SCRIPT_REL_PATH"
BUSYBOX_BINS='sh echo cat ls df tail sed cut mount umount md5sum pwd grep basename dirname tr kill killall sleep'
local SCRIPT_MOUNT_DIR=""

if [ "x$SCRIPT_REL_PATH" != "xdev/shm" ]; then
	SCRIPT_MOUNT_DIR="$SCRIPT_REL_PATH"
fi
if [ $UPGRADING -eq 1 ]; then
	REBIND_DIRS="$SCRIPT_MOUNT_DIR sys etc dev/shm dev proc"
else
	REBIND_DIRS="proc sys dev dev/shm etc $SCRIPT_MOUNT_DIR"
fi
}

chroot_and_fork()
{
	rebase
	exec chroot $CHROOT_DIR "$SCRIPT_PATH/$SCRIPT_NAME" -dir $SCRIPT_PATH
	runtime_error 9 "Exec failed"
}

kill_apps()
{
	echo Stopping Applications
	$LCDC -c2 -2"Stopping Apps" 
	killall menu 2>/dev/null
	killall audio 2>/dev/null
	killall record 2>/dev/null
	killall service_main 2>/dev/null
	killall mplayer 2>/dev/null
	killall -SIGKILL jhencoder 2>/dev/null
	killall -SIGKILL sndfile-deinterleave 2>/dev/null
	killall -SIGKILL lame 2>/dev/null
}

start_upgrade()
{
	echo "----Restarting from CHROOTed environment----"
	SCRIPT_PATH=$1
	if [ "x$SCRIPT_PATH" == "x" ]; then
		runtime_error 10 "Can't upgrade, Path parameter missing"
	fi
	cd $SCRIPT_PATH
	setup_environment
	kill_apps
	$LCDC -c1 -1"$MSG_NO_RESTART"
	do_upgrade
	do_reboot
	unbind_dirs
}


if [ "x$1" == "x-dir" ]; then
	UPGRADING=1
	start_upgrade $2
else
	export LD_LIBRARY_PATH=.
	$LCDC -c1 -c2 -1"$MSG_NO_RESTART"
	setup_environment
	do_sanity_check
	chroot_and_fork
fi
exit 0

