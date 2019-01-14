mount -o remount,rw /dev/mmcblk0p1 /mnt/floppy
cp /dev/mtd0 /mnt/floppy/u-boot.bin
cp /dev/mtd3 /mnt/floppy/rootfs.cramfs
mount -o remount,rw /dev/mmcblk0p1 /mnt/floppy
cp /dev/mtd1 /mnt/floppy/uImage
