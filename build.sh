#!/bin/bash
set -e      # exit on error
# set -x    # printf commands
# set -v    # print commands
# set -n    # check syntax
export OBJ=/src/apc.io/obj.testing
export KERNEL_SRC=/src/apc.io/linux-vtwm-testing
export PATH=~/apc.io/apc-8750-master/u-boot/tools:$PATH
export PATH=/opt/local/arm/arm-2014.05/bin:$PATH
compile()
{
# make O=${OBJ} ARCH=arm CROSS_COMPILE=arm-none-eabi- vmlinux  -j 3
make -C $KERNEL_SRC O=$OBJ ARCH=arm CROSS_COMPILE=arm-none-eabi- zImage -j 3
mv $OBJ/arch/arm/boot/zImage $1/$2/ ;
make -C $KERNEL_SRC O=$OBJ ARCH=arm CROSS_COMPILE=arm-none-eabi- dtbs
cat $1/$2/zImage $OBJ/arch/arm/boot/dts/wm8750-apc8750.dtb > $1/$2/zImage_w_dtb
mkimage -A arm -O linux -T kernel -C none -a 0x8000 \
     -e 0x8000 -n "My Linux" -d $1/$2/zImage_w_dtb $1/$2/uzImage.bin
}
if [ $# -eq 0 -o "$1"c = "helpc" ]; then
	# help
	printf "\txconfig\n"
	printf "\t\tConfigure kernel. You may find it useful to copy one of\n"
	printf "\t\tthe config files avilable on this site before doing this\n"
	printf "\n"
	printf "\tclean\n"
	printf "\t\tcleanup build area\n"
	printf "\n"
	printf "\tdistclean\n"
	printf "\t\tdistclean OBJ area\n"
	printf "\n"
	printf "\tmrpropoer\n"
	printf "\t\tmrproper OBJ area\n"
	printf "\n"
	printf "\tinit\n"
        printf "\t\tCreate initramfs_data/init\n"
        printf "\n"
	printf "\tinitramfs\n"
	printf "\t\tCreate the small initramfs image used for booting\n"
	printf "\t\tinto Slackware installer.\n"
	printf "\n"
        printf "\tinitramfsall\n"
        printf "\t\tCreate the small initramfs image used for booting\n"
        printf "\t\tinto Slackware installer, from initrd.gz\n"
        printf "\n"
	printf "\tcpio\n"
        printf "\t\tCreate cpio image from uinitrd-kirkwood.img\n"
	printf "\n"
        printf "\tboot vga\n"
        printf "\t\tCreate uzImage.bin used for booting installed Slackware\n"
        printf "\t\tconsole is on vga\n"
	printf "\n"
        printf "\tboot ttyWMT0\n"
        printf "\t\tCreate uzImage.bin used for booting installed Slackware\n"
        printf "\t\tconsole is on serial ( ttyWMT0 )\n"
	printf "\n"
        printf "\tboot generic\n"
        printf "\t\tCreate uzImage.bin used for booting installed Slackware\n"
        printf "\t\tconsole is on vga. Accepts bootloader kernel parameters\n"
	printf "\n"
        printf "\tinstall vga\n"
        printf "\t\tCreate uzImage.bin used for booting into installer for\n" 
	printf "\t\tSlackware. console is on serial ( vga )\n"
	printf "\n"
        printf "\tinstall ttyWMT0\n"
        printf "\t\tCreate uzImage.bin used for booting into installer\n"
	printf "\t\tfor Slackware. console is on serial ( ttyWMT0 )\n"
	printf "\n"
        printf "\tinstall generic\n"
        printf "\t\tCreate uzImage.bin used for booting into installer\n"
	printf "\t\tfor Slackware. Accepts bootloader kernel parameters\n"
	printf "\n"
	printf "\tgen_init_cpio\n"
	printf "\t\trun kernel gen_init_cpio utility for generating initramfs\n"
	printf "\t\tcpio archive. Input file is cpio_list.txt\n" 
	printf "\n"
	printf "\tuinitrd\n"
	printf "\t\tcreate uinitrd image from initramfs\n"
	printf "\n"

elif [ "$1"c = "allc" ]; then
	# build all targets
	sh $0 boot vga;
	sh $0 boot ttyWMT0;
	sh $0 boot generic;
	sh $0 install vga;
	sh $0 install ttyWMT0;
	sh $0 install generic;

elif [ "$1"c = "xconfigc" ]; then
	# run kernel xconfig 
	make -C $KERNEL_SRC O=$OBJ ARCH=arm CROSS_COMPILE=arm-none-eabi- xconfig 
elif [ "$1"c = "cleanc" ]; then
	# clean up build area
	rm -rf boot
	rm -rf install
	rm -f initramfs_data.cpio.gz
	rm -f initrd-kirkwood.cpio
	rm -f scriptcmd

elif [ "$1"c = "distcleanc" ]; then 
	# clean up kernel area
	# to clean up kernel src area, unset OBJ
	make -C $KERNEL_SRC O=$OBJ ARCH=arm CROSS_COMPILE=arm-none-eabi-  distclean 

elif [ "$1"c = "mrproperc" ]; then
	# clean up kernel area
	# to clean up kernel src area, unset OBJ
	make -C $KERNEL_SRC O=$OBJ ARCH=arm CROSS_COMPILE=arm-none-eabi-  mrproper

elif [ "$1"c = "initrdc" ]; then 
	# old style initrd
	# create an ext2 fs image, populate with files in initramfs_data and gzip the image
	# require su powers	
	initrdsize=`du -s -B512  initramfs_data | cut -f 1,1`	
	dd if=/dev/zero of=initrd count=$initrdsize
	mkfs.ext2 initrd
	test -d fs || mkdir fs
	mount -o loop initrd fs
	(cd initramfs_data; tar cf - * ) | (cd fs ; tar xf - )
	sync
	umount fs
	gzip initrd
elif [ "$1"c = "initramfsall" ]; then
	gunzip initrd.gz
	mkdir initramfs_data
	mount -o loop initrd initramfs_data
	# create initramfs_data/init as shown above
	sh build.sh init
	chmod a+x initramfs_data/init
	sync
	(cd initramfs_data ; find . | cpio -o -H newc | gzip  > ../initramfs_data.cpio.gz )
	umount init_ramfs_data
	gzip initrd
elif [ "$1"c = "initramfsc" ]; then
	# create compressed cpio archive from initramfs_data dir
	(cd initramfs_data ; find . | cpio -o -H newc | gzip  > ../initramfs_data.cpio.gz )	
	cp initramfs_data.cpio.gz $KERNEL_SRC/usr

elif [ "$1"c = "cpioc" ]; then
	# convert uinitrd-kirkwood.img to simple cpio archive
	dd if=./uinitrd-kirkwood.img bs=64 skip=1 of=initrd-kirkwood.cpio.gz
        gunzip initrd-kirkwood.cpio.gz

elif [ "$1"c = "scriptcmdc" ]; then
	# create u-boot scriptcmd
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Slackboot: scriptcmd" -d scriptcmd.txt scriptcmd

elif [ "$1"c = "extractc" ]; then
	# extract old style initrd.gz to initramfs_data
	# requrie su powers
	test -f initrd || gunzip initrd.gz
	mount -o loop initrd fs
	(cd fs; tar cf - *) | (cd initramfs_data; tar xf - )
	umount fs
	gzip initrd

elif [ "$1"c = "gen_init_cpio" ]; then
	# create initramfs_data.cpio.gz from cpio_list.txt
	gen_init_cpio cpio_list.txt > initramfs_data.cpio

elif [ "$1"c = "uinitrd" ]; then
	# create uinitrd image from initramfs_data
	mkimage -A arm -T ramdisk -C none -n "u-boot initramfs image" -d ./initramfs_data uInitrd
	
elif [ "$1"c = "initc" ]; then

cat << 'EOF' > ./initramfs_data/init
#!/bin/busybox sh
/bin/busybox mount -t proc /proc
/bin/busybox mount -t sys /sys
/bin/busybox echo /sbin/mdev > /proc/sys/kernel/hotplug
/bin/busybox mdev -s
/bin/busybox --install 
mkfs.ext2 /dev/ram0
mkdir /root
mount /dev/ram0 /root
cd /root
mkdir /flash
mount /dev/mmcblk0p1 /flash
cpio -id < /flash/initrd-kirkwood.cpio
umount /flash
exec chroot /root /bin/busybox init
exec /bin/busybox init
EOF

else

case $1 in
	boot)
	test -d $1/$2 || mkdir -p $1/$2;
	# create uzImage.bin for booting with root=/dev/mmcblk0p2
	rm -f $OBJ/usr/initramfs_data.cpio.gz
	case $2 in
		ttyWMT0)
		# uzImage.bin has console on ttyWMT0, no bootloader kernel parameters, root=/dev/mmcblk0p2
		cp configs/config.slackboot.ttyWMT0 $OBJ/.config
		cp configs/config.slackboot.ttyWMT0 $1/$2/config
		;;
		vga)
		# uzImage.bin has console on vga, no bootloader kernel parameters, root=/dev/mmcblk0p2
		cp configs/config.slackboot.vga $OBJ/.config
		cp configs/config.slackboot.vga $1/$2/config
		;;
		generic)
		# uzImage.bin accepts bootloader kernel parameters, console on vga
		cp configs/config.slackware.generic $OBJ/.config
		cp configs/config.slackware.generic $1/$2/config
		;;
	esac
	compile $1 $2;
	;;
	install)
	test -d $1/$2 || mkdir -p $1/$2;
	test -f initramfs_data.cpio.gz || sudo $0 initramfs
	cp initramfs_data.cpio.gz $OBJ/usr
	cp initramfs_data.cpio.gz $1/$2/
	if [ ! -f ./initrd-kirkwood.cpio ]; then
	 # dd if=uinitrd-kirkwood.img of=initrd-kirkwood.cpio.gz skip=64 bs=1
	 dd if=uinitrd-kirkwood.img of=initrd-kirkwood.cpio.gz skip=64 bs=1
	gunzip ./initrd-kirkwood.cpio.gz
	fi
	case $2 in
		ttyWMT0)
		# uzImage.bin has console on ttyWMT0, no bootloader kernel parameters, loads initrd-kirkwood.cpio
		cp configs/config.slackinst.ttyWMT0 $OBJ/.config
		cp configs/config.slackinst.ttyWMT0 $1/$2/config
		cp initrd-kirkwood.cpio $1/$2
		;;
		vga)
		# uzImage.bin has console on vga, no bootloader kernel parameters, loads initrd-kirkwood.cpio
		cp configs/config.slackinst.vga $OBJ/.config
		cp configs/config.slackinst.vga $1/$2/config
		cp initrd-kirkwood.cpio $1/$2
		;;
		generic)
		# uzImage.bin accepts bootloader kernel parameters, loads initrd-kirkwood.cpio, console on vga
		cp configs/config.slackware.generic $OBJ/.config
		cp configs/config.slackware.generic $OBJ/.config
		cp configs/config.slackware.generic $1/$2/config
		;;
	esac
	compile $1 $2;
	;;
	*)
	sh $0 help
	;;		
esac
fi
