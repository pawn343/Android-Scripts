#!/system/bin/sh

#
# linux deploy script to run linux rootfs on Android or similiar
# 
# last updated: 05/04/2019 01:23 (version)
# created by bluesec7
# https://kagurasuki.blogspot.com
#

# SET UP ENV VAR
rootfs=$EXTERNAL_STORAGE/linux.img
mount_point=/data/local/mnt
chroot_dir=$mount_point/kali-armhf # root path of your rootfs
shell="/bin/bash" # the linux shell

loop_number=255
loop=/dev/block/loop$loop_number

run=true
limit=3
bbox=busybox


# Initialization
init(){
	if [[ -e $rootfs ]];then
		echo "Your rootfs: $rootfs"
	else
		echo "Couldn't find Your rootfs in $rootfs"; exit 1
	fi
	if [[ ! -e $mount_point ]]; then
		echo "Your mount point in $mount_point is not exists"
		echo -n "Would you like me to create it? [y/n] "
		read nanya
		case $nanya in
			(y|Y) mkdir $mount_point;;
			(*) echo "No? Okay.."; exit 1;;
		esac
	fi
	echo "Your mount point: $mount_point"
	
}


# SUB FUNC todo things #
check_busybox(){
	# busybox is needed in order to do some stuff ;)
	/system/xbin/busybox
}

check_root(){
	# are you root ? root is needed to chrooting to the linux itself
	echo "test"
}

fun_line(){
	count=0
	amount=15
	if [[ ! $2 = "" ]]; then
		amount=$2
	fi
	while (( $count < $amount ));
	do
		echo -n "$1"
		count=$((count+1))
	done
	echo
}


# MAIN FUNC #
start_linux(){
	echo "Starting.."
	check_loop(){
	echo -n "Loop device is "
	#  check loop device #
	if [ -b $loop ]; then
		echo "[ FOUND ]"
	else
		echo "[ MISSING ]"
		echo -n "Creating loop device $loop ... "
		$bbox mknod $loop b 7 $loop_number # change this according to the last number on $loop var. or simply change the $loop_number var
		if [[ $? = 0 ]]; then
			echo "[ OK ]"
		else
			echo "[ FAIL ]"
			exit 1
		fi
	fi
	}
	
	check_attached(){
	# check if it already attached
	$bbox losetup $loop|grep $rootfs
	if [[ $? -ne 0 ]]; then
		echo -n "Attaching $rootfs to $loop "
		$bbox losetup $loop $rootfs
		if [[ $? = 0 ]]; then
			echo "[ OK ]"
		else
			echo "[ FAIL ]"
			exit 1
		fi
	else
		echo "$rootfs is Already attached"
	fi
	}
	
	check_mounted(){
	# check if it already mounted
	mount|grep -o $loop
	if [[ $? -ne 0 ]]; then
		echo -n "Mounting $loop to $mount_point "
		$bbox mount -t ext4 $loop $mount_point
		if [[ $? = 0 ]]; then
			echo "[ OK ]"
		else
			echo "[ FAIL ]"
			exit 1
		fi
	else
		echo "$loop is Already mounted"
	fi
	}
	
	mount|grep " $mount_point "
	if [[ $? = 0 ]]; then
		echo "$mount_point already mounted"
	else
		check_loop
		check_attached
		check_mounted
	fi
	echo "Setting up system.."
	######### EXPORT ENVIRONMENT #########
	export bin=/system/bin
	export mnt=$mount_point
	PRESERVED_PATH=$PATH
	export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH
	export TERM=linux
	export HOME=/root
	export USER=root
	export LOGNAME=root
	export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
	export CLASSPATH=.:$CLASSPATH
	unset LD_PRELOAD
	
	if [ ! -e $chroot_dir/dev/net/tun ]; then
		# JUST ONCE MOUNT
		$bbox mount -t proc proc $chroot_dir/proc/
		$bbox mount -t sysfs sys $chroot_dir/sys/
		$bbox mount -o bind /dev $chroot_dir/dev/
		
		if [ $? -ne 0 ];then echo "Unable to mount system!"; exit 1; fi
		
		if [ ! -e $chroot_dir/dev/net ]; then
			mkdir $chroot_dir/dev/net
			chmod 0755 $chroot_dir/dev/net
			ln $chroot_dir/dev/tun $chroot_dir/dev/net/tun
		fi
	fi
	
	echo "Setting up network.."
	$bbox sysctl -w net.ipv4.ip_forward=1
	if [ $? -ne 0 ];then echo "Unable to forward network!"; exit 1; fi
	
	setup_nameserver(){
	# Check if you are Online
	if [[ ! `ip route` ]]; then
		echo "[ ! ] No internet detected!\nFollowing nameserver maybe deprecated."
		# i use this to solve dns resolver error (can't get ip addr)
		# this script will automatically get the default android nameserver and put it on resolv.conf file
	fi
	# setup DNS nameservers
	echo "# Configured nameservers at `date`" > $chroot_dir/etc/resolv.conf
	echo "## OpenDNS ##
nameserver 208.67.222.222
nameserver 208.67.220.220

## Google DNS ##
nameserver 8.8.8.8
nameserver 8.8.4.4

" >> $chroot_dir/etc/resolv.conf

	count=1
	dns=0
	while true
	do
		nameserver=`getprop net.dns$count`
		if [[ ! $nameserver ]]; then
			break
		fi
		echo "[ * ] Found nameserver: $nameserver"
		echo "nameserver $nameserver" >> $chroot_dir/etc/resolv.conf
		count=$((count+1))
		dns=$((dns+1))
	done
	}
	setup_nameserver
	
	echo "Chrooting to $shell at $chroot_dir"
	$bbox chroot $chroot_dir $shell -i
	echo "!!! SHUTTING DOWN NOW !!!"
	uname -a
	exit 0
}


stop_linux(){
	echo "STOP is currently unavailable ;)"
}

install_linux(){
	echo "INSTALL is currently unavailable ;)"
}

ask(){
	fun_line "#" 60
	echo "what you want todo?
\t[s]tart linux\n\t[S]top linux\n\t[i]install linux\n\t[e]xit or [q]uit to exit.\n"
	echo -n "Please select one: "
	read -n 1 tanya
	echo "\n"
	case $tanya in
		(s) start_linux;;
		(S) stop_linux;;
		(i) install_linux;;
		(q|e) echo "OK see you :')"; exit 0;;
		(*) fun_line "*" 60; echo "( ? ) What is \"$tanya\"?\n"; fun_line "*" 60;
		exit 1
	;;esac
	
}

# main loop #
main(){
	init
	while $run
	do
		ask
	limit=$((limit-1))
	if [[ $limit = 0 ]]; then
		break
	fi
	done
}

main