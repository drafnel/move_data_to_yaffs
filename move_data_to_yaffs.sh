#!/system/xbin/sh

# move_data_to_yaffs.sh
#
# Move select subdirectories from the ext4 /data/data directory onto the
# quicker yaffs /datadata directory and create symbolic links in their place.
#
#
# This script is designed for Cyanogenmod 7.X on Samsung Galaxy S (tested
# with Vibrant) for users who have moved their app data from /datadata back
# to /data/data using a procedure like:
#
#    cp -a /datadata /data/data.new &&
#    rm -f /data/data &&
#    mv /data/data.new /data/data
#
# This script then moves select subdirectories from each app back onto the
# faster yaffs filesystem.  It should improve app startup and runtime
# interactivity.
#
# This script may be run multiple times and should be run after one or more
# new apps are installed.  I just keep this script in /datadata and run it
# whenever I need to from a terminal, but you can put it in /system/bin, or
# someplace else, if you like.
#
# Background
# On Samsung Galaxy S, cyanogenmod 7 creates a ~175MB yaffs partition which
# holds all app data.  This partition is mounted at /datadata and the usual
# location of this directory at /data/data is a symbolic link that points
# to /datadata.
#
#    $ ls -l /data/data
#    lrwxrwxrwx    1 system    system    9 Oct  8 19:34 /data/data -> /datadata
#
# The app apk itself does not reside here, but data created by the app resides
# here, especially, the app's sqlite databases and user preference xml files.
# The cyanogenmod developers did it this way to address the lag experienced on
# the stock Galaxy S firmware.  But, this produces a problem.
#
# The /datadata partition is quite small and may be filled up quickly by an
# app that caches a lot of data (g+ for example).  Once /datadata fills up,
# apps will begin force closing since they will not be able to create any new
# data on /datadata.  The ext4 /data partition, which is about 2GB, has plenty
# of space free.  So, it is attractive to move /datadata onto this large
# partition.  But then we have the lag problem again.  That's where this script
# comes in.  It moves certain subdirectories from each app back onto the low
# latency yaffs partition (mainly sqlite database files and xml config files)
# and keeps the large cached files that an app may create or download on the
# much larger 2GB ext4 partition.

# Move these app subdirectories
dirs_to_move='databases shared_prefs opera app_databases'

# Skip these apps
# Barnes & Nobles keeps a few processes running in the background *all-the-time*
# for some reason.  If you move its databases while these are running,
# then the app no longer works correctly, so skip it.
# * You can clear its data (or maybe log out) which will stop these processes,
# and then create the symbolic links by hand if you want.  Once you log in,
# the new files will be created in /datadata and the app will work correctly.
# The Amazon Kindle app and Google Books app do not have this problem.
skip_apps='bn.ereader'

datadata='/data/data'
yaffs='/datadata'

dryrun=

# OPTIONS
# -n    dryrun
while case "$1" in -?) :;; *) false;; esac; do
	case "$1" in
	-n)
		dryrun=1
		;;
	*)
		echo 1>&2 "Error: unrecognized option $1"
		exit 1
		;;
	esac
	shift
done

test -L "$datadata" && {
	echo 1>&2 "Error: <$datadata> is a symbolic link, aborting"
	exit 1
}

# process app directory
# move app data to yaffs filesystem
# create symbolic links to point to it
cd "$datadata" &&
{ test $# != 0 || set -- *; } &&
for app in "$@"; do
	echo " $skip_apps " | grep " $app " >/dev/null 2>&1 && continue
	for d in $dirs_to_move; do
		if [ ! -L "$app/$d" -a -d "$app/$d" ]; then
			echo "Processing $app/$d..." &&
			{ test "x$dryrun" = 'x' || continue; } &&
			if [ -d "$yaffs/$app/$d" ]; then
				rm -r "$yaffs/$app/$d"
			fi &&
			tar -cf - "$app/$d" | tar -C "$yaffs" -xf - &&
			rm -r "$app/$d" &&
			ln -s "$yaffs/$app/$d" "$app/$d" &&
			chmod 775 "$yaffs/$app" ||
				echo 1>&2 "Error: failed moving $app/$d"
		fi
	done
done

# remove uninstalled app data
cd "$yaffs" &&
for app in *; do
	if [ -d "$app" -a ! -e "$datadata/$app" ]; then
		echo "Removing stale app data for $app..." &&
		{ test "x$dryrun" = 'x' || continue; } &&
		rm -r "$app" ||
			echo 1>&2 "Error: failed removing stale data for $app"
	fi
done
