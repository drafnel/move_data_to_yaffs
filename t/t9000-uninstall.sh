#!/bin/sh
#
# Copyright (c) 2012 Brandon Casey
#

test_description='Test uninstall.sh functionality'

. ./test-lib.sh

test_expect_success 'Uninstall works' '
	move_data_to_yaffs.sh &&
	test -d "$MDTY_DATADATA" &&
	app_installed_with_symlinks "$TEST_APP" &&
	for app in $MDTY_SKIP_APPS; do
		app_installed_full "$app" || return 1
	done
	uninstall.sh &&
	test -L "$MDTY_DATADATA" &&
	for app in $TEST_APP $MDTY_SKIP_APPS; do
		app_installed_full "$app" || return 1
	done
'

test_done
