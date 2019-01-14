#!/bin/sh
export PATH=$PATH:/usr/local/sbin
wait_for_device() {
	RESULT=1
	if [ $# == 2 ]; then
		MOUNT_POINT=$1
		TIMEOUT=$2
		i=0
		while [ $i -le $TIMEOUT ]; do
	        mount | grep $MOUNT_POINT > /dev/null
			if [ $? == 0 ]; then
				RESULT=0
				break
			else
				sleep 1
				i=`expr $i + 1`
			fi
		done

	fi
	echo $RESULT
}


MMC_MOUNT_POINT=/mnt/floppy

setup_gpios() {
	modprobe tracker_leds
	for i in 47 32 33 41 42; do
		echo $i > /sys/class/gpio/export
		echo 0 > /sys/class/gpio/gpio$i/value
	done
	#ACT
	echo 1 > /sys/class/gpio/gpio33/value
}


start_system_services() {
	/etc/rc.d/init.d/network start
}

enable_sdio_devices() {
	modprobe sddetect slot=1	
}

load_kernel_modules() {
	modprobe ehci-hcd
	modprobe tracker_buttons
	modprobe 8189es.ko
}

wait_for_sd_card() {
	ret=$(wait_for_device "$MMC_MOUNT_POINT" 10)
}

start_jamhub_services() {
	/usr/bin/audio&
	/usr/bin/menu&
	LD_LIBRARY_PATH=/usr/local/networkservice /usr/local/networkservice/service_main >/dev/null 2>&1 &
}


REBOOT=0
CONFIG_LED=32

blink_led()
{
	local i=0
	while [ 1 ]; do
		echo 1 > /sys/class/gpio/gpio$CONFIG_LED/value
		sleep 1
		echo 0 > /sys/class/gpio/gpio$CONFIG_LED/value
		sleep 1
		let i+=1
		if [ $i -eq 5 ]; then
			break
		fi
	done
}


set_led()
{
	if [ "x$1" == "x0" ]; then
		echo 0 > /sys/class/gpio/gpio$CONFIG_LED/value
	else
		echo 1 > /sys/class/gpio/gpio$CONFIG_LED/value
	fi
	
}



disable_dhcp()
{
	fw_printenv  | grep bootargs_nor= | grep dhcp > /dev/null
	if [ $? -eq 0 ]; then
		echo Disabling DHCP during booting..
		fw_setenv bootargs_nor 'setenv bootargs ${bootargs} root=/dev/mtdblock${fw_rootfs_mtd} rootfstype=cramfs'
	fi
}


get_setting()
{
	local value=""
	if [ "x$1" != "x" ]; then
		value=$(fw_printenv | grep "$1=" | sed  's/=/ /' | awk '{for (i=2; i<=NF; i++) print $i}')
	fi
	echo -n $value
}

get_uboot_setting()
{
	local value=""
	if [ "x$1" != "x" ]; then
		value=$(fw_printenv -u | grep "$1=" | sed  's/=/ /' | awk '{for (i=2; i<=NF; i++) print $i}')
	fi
	echo -n $value
}


setup_critical_variables()
{
	if [ -e $MMC_MOUNT_POINT/noautoconfig ]; then
		echo Autoconfig disabled!!
		return
	fi
	local DEFAULT_MAC="70:B3:D5:3A:80:00"
	

	v=$(get_uboot_setting "ethprime")
	echo "[ethprime=$v]"
	if [ "x$v" != "xFEC0" ]; then
		echo Setting ethprime
		fw_setenv -u ethprime
		fw_setenv -u ethprime FEC0
		REBOOT=1
	fi
	

	local EMPTY_MAC=0
	local SET_MAC=0
	local SET_NOR_MAC=0

	v=$(get_uboot_setting "fec_addr")
	nor_mac=$(get_setting "fec_addr")

	if [ "x$v" == "x" ]; then
		EMPTY_MAC=1
		SET_MAC=1
	else
		if [ "x$v" == "x$DEFAULT_MAC" ]; then
			SET_MAC=1
		fi
	fi

	if [ "x$nor_mac" == "x" ]; then
		SET_NOR_MAC=1
	else
		if [ "x$nor_mac" == "x$DEFAULT_MAC" ]; then
			SET_NOR_MAC=1
		fi
	fi



	echo "[fec_addr=$v]"
	if [ $SET_MAC -eq 1 ]; then
		if [ $SET_NOR_MAC -eq 0 ]; then
			v=$nor_mac
		else
			if [ -e $MMC_MOUNT_POINT/mac_address ]; then
				local mac=$(cat $MMC_MOUNT_POINT/mac_address)
				echo "$mac" | grep -E '..:..:..:..:..:..' > /dev/null
				if [ $? -eq 0 ]; then
					v=$mac
				fi
			fi
		fi
		
		if [ "x$v" == "x" ]; then
			v="$DEFAULT_MAC"
		fi

		if [ "x$v" == "x$DEFAULT_MAC" ]; then
			if [ $EMPTY_MAC -eq 1 ]; then
				echo Setting fec_addr [$v]
				fw_setenv -u fec_addr $v 
				REBOOT=1
			fi
		else
			if [ $SET_MAC -eq 1 ]; then
				echo Setting fec_addr [$v]
				fw_setenv -u fec_addr $v 
				REBOOT=1
			fi
			if [ $SET_NOR_MAC -eq 1 ]; then
				echo Setting NOR MAC [$v]
				fw_setenv fec_addr $v 
			fi

		fi
	fi
	
}



validate_uboot_variables()
{
	set_led
	disable_dhcp
	setup_critical_variables
	if [ $REBOOT -eq 1 ]; then
		blink_led
		echo Rebooting..
		reboot
	else
		set_led 0
	fi
}



main() {
	start_system_services
	setup_gpios
	enable_sdio_devices
	wait_for_sd_card
	validate_uboot_variables
	load_kernel_modules
	touch /tmp/jamhub_init.done
	
	if [ -e $MMC_MOUNT_POINT/noautostart ]; then
		echo Autostatup disabled!! Exiting..
		exit 0
	fi
	
	start_jamhub_services
	if [ -e $MMC_MOUNT_POINT/autostart.sh ]; then
		echo Executing Autostatup script...
		sh $MMC_MOUNT_POINT/autostart.sh &
	fi
}

mode=$1
if [ "x$mode" == "xstart" ]; then
	main
fi
