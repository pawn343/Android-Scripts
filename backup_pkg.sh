#!/system/bin/sh

# Script to backup your favorite Android apps without root #
# License: FreeLicense
# Author: RedFoX a.k.a bluesec7
# visit my blog: kagurasuki.blogspot.com
# social accounts: fb.com/silent.v0id - t.me/silent_void
# Any suggestions are welcome


save_dir=`pwd`


usage () {
	echo "Usage:\n\t$0 <package_name>"
	exit 1
}

die (){
	echo $*
	exit 1
}

main(){
	if [ ! $2 ]; then
		echo "Using default path $save_dir to save file.\n"
	else
		save_dir=$2
	fi
	if [ ! -d $save_dir ]; then
		die "No dir named $save_dir in `pwd`"
	fi
	pkg=`pm path $1`
	if [ ! $pkg ]; then
		die "[ ! ] There's no such package named \"$1\""
	else
		pkg_path=${pkg##*:}
		pkg_name="${pkg_path##*/}"
		echo "~Backuping $pkg_name to $save_dir"
		 cp $pkg_path $save_dir
		if [ $? != 0 ]; then
			die "\n[ ! ] There's an error while backuping $pkg_name to $save_dir"
		fi
		echo "- Done!"
	fi
}


if [ ! $1 ]; then
	usage
else
	main $1 $2
fi