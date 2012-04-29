#!/bin/bash

# Stolen and simplified from the git project

install_app()
{
	if [ $# -ne 1 ]; then
		echo 1>&2 "Usage: $FUNCNAME app_name"
		return 1
	fi

	local app_name=$1; shift

	local dirs='cache databases files lib shared_prefs'
	local files='lib/lib.so databases/example.db shared_prefs/preferences.xml'

	(
		mkdir "$MDTY_DATADATA/$app_name" || exit
		for dir in $dirs; do
			mkdir -p "$MDTY_DATADATA/$app_name/$dir" || exit
		done

		for file in $files; do
			:>"$MDTY_DATADATA/$app_name/$file" || exit
		done
	)
}

uninstall_app()
{
	if [ $# -ne 1 ]; then
		echo 1>&2 "Usage: $FUNCNAME app_name"
		return 1
	fi

	local app_name=$1; shift

	(
		cd "$MDTY_DATADATA" &&
		rm -rf "$app_name"
	)
}

app_installed_full()
{
	if [ $# -ne 1 ]; then
		echo 1>&2 "Usage: $FUNCNAME app_name"
		return 1
	fi

	local app_name=$1; shift

	local dirs='cache databases files lib shared_prefs'
	local files='lib/lib.so databases/example.db shared_prefs/preferences.xml'

	local dir file

	test -d "$MDTY_DATADATA/$app_name" || return 1
	for dir in $dirs; do
		test -d "$MDTY_DATADATA/$app_name/$dir" || return 1
	done
	for file in $files; do
		test -f "$MDTY_DATADATA/$app_name/$file" || return 1
	done
}

app_installed_with_symlinks()
{
	if [ $# -ne 1 ]; then
		echo 1>&2 "Usage: $FUNCNAME app_name"
		return 1
	fi

	local app_name=$1; shift

	local dirs='cache databases files lib shared_prefs'
	local files='lib/lib.so databases/example.db shared_prefs/preferences.xml'

	local dir file

	test -d "$MDTY_DATADATA/$app_name" || return 1
	for dir in $dirs; do
		if echo " $MDTY_DIRS_TO_MOVE " | grep " $dir " >/dev/null 2>&1
		then
			test -L "$MDTY_DATADATA/$app_name/$dir" || return 1
		else
			test -d "$MDTY_DATADATA/$app_name/$dir" || return 1
		fi
	done
	for file in $files; do
		test -f "$MDTY_DATADATA/$app_name/$file" || return 1
	done
}

setup_()
{
	if [ $# -ne 1 ]; then
		echo 1>&2 "Usage: $FUNCNAME test_dir"
		return 1
	fi

	local test_dir=$1; shift

	mkdir -p "$test_dir"
	(
		cd "$test_dir" &&
		mkdir -p "$MDTY_YAFFS" &&
		mkdir -p "$(dirname "$MDTY_DATADATA")" &&
		ln -s "$MDTY_YAFFS" "$MDTY_DATADATA" &&
		for app in $TEST_APP $MDTY_SKIP_APPS; do
			install_app $app || return 1
		done
	) || exit
}

test_eval_ () {
	# This is a separate function because some tests use
	# "return" to end a test_expect_success block early.
	eval </dev/null >&3 2>&4 "$*"
}

test_run_ () {
	test_eval_ "$1"
}

test_expect_success()
{
	test_count=$(($test_count+1))
	test_run_ "$2" &&
		echo "ok $test_count - $1" || {
		echo "not ok - $test_count $1"
		exit 1
	}
}

PATH="`pwd`/../bin-wrappers:$PATH"
export PATH

TEST_APP='org.example.test'

TEST_DIRECTORY=`pwd`

test="trash directory.$(basename "$0" .sh)"
TRASH_DIRECTORY="$TEST_DIRECTORY/$test"

MDTY_DIRS_TO_MOVE='databases shared_prefs opera app_databases'
MDTY_SKIP_APPS='org.example.skip_app_1 org.example.skip_app_2'
MDTY_DATADATA="$TRASH_DIRECTORY/data/data"
MDTY_YAFFS="$TRASH_DIRECTORY/datadata"

export MDTY_DIRS_TO_MOVE MDTY_SKIP_APPS MDTY_DATADATA MDTY_YAFFS

rm -rf "$test" || {
	echo 1>&2 "FATAL: Cannot prepare test area"
	exit 1
}

test ! -z "$DEBUG" || remove_trash=$TRASH_DIRECTORY
setup_ "$test"
cd -P "$test" || exit 1

# To allow future redirection of stdout/stderr for tests
if test ! -z "$DEBUG"; then
	exec 4>&2 3>&1
else
	exec 4>/dev/null 3>/dev/null
fi

test_count=0

test_done()
{

	echo "# passed all $test_count test(s)"
	echo "1..$test_count"

	test -d "$remove_trash" &&
	cd "$(dirname "$remove_trash")" &&
	rm -rf "$(basename "$remove_trash")"
}
