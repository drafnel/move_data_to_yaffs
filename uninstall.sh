#!/system/xbin/sh
#
# Revert movement of /datadata to /data/data
#
# Copyright (c) 2012 "Brandon Casey" <drafnel@gmail.com>

datadata=${MDTY_DATADATA:-'/data/data'}
yaffs=${MDTY_YAFFS:-'/datadata'}

if [ -L "$datadata" ]; then
	echo 1>&2 "Nothing to do."
	exit 1
fi

set -- `df -P "$yaffs" | tail -n 1`
target_free_space=$4

set -- `du -s "$datadata"`
source_size=$1

if [ "$target_free_space" -lt "$source_size" ]; then
	echo 1>&2 "Error: not enough space on <$yaffs>"
	exit 1
fi

cd "$datadata" &&
for app in *; do
	if [ -d "$yaffs/$app" ]; then
		for d in "$app/"*; do
			test -e "$d" || continue
			if [ ! -d "$yaffs/$d" -o ! -L "$d" ]; then
				rm -r "$yaffs/$d"
				cp -a "$d" "$yaffs/$app/"
			fi || {
				echo 1>&2 "Error: failed moving $d, aborting"
				exit 1
			}
		done
	else
		cp -a "$app" "$yaffs/" || {
			echo 1>&2 "Error: failed moving $app, aborting"
			exit 1
		}
	fi
done &&
cd / &&
rm -r "$datadata" &&
ln -s "$yaffs" "$datadata"
