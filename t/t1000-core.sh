#!/bin/sh
#
# Copyright (c) 2012 Brandon Casey
#

test_description='Test move_data_to_yaffs.sh functionality'

. ./test-lib.sh

test_expect_success 'Dry-run leaves apps/dirs alone' '
	test -L "$MDTY_DATADATA" &&
	app_installed_full "$TEST_APP" &&
	move_data_to_yaffs.sh -n &&
	test -L "$MDTY_DATADATA" &&
	app_installed_full "$TEST_APP"
'

test_expect_success 'Moving data to data/data works' '
	test -L "$MDTY_DATADATA" &&
	app_installed_full "$TEST_APP" &&
	move_data_to_yaffs.sh &&
	test -d "$MDTY_DATADATA" &&
	app_installed_with_symlinks "$TEST_APP"
'

test_expect_success 'skip_apps were skipped' '
	for app in $MDTY_SKIP_APPS; do
		app_installed_full "$app" || return 1
	done
'

test_expect_success 'move_data_to_yaffs.sh exit success when nothing to do' '
	move_data_to_yaffs.sh
'

test_expect_success 'Specifying one app on command line works' '
	install_app test_app2 &&
	install_app test_app3 &&
	install_app test_app4 &&
	install_app test_app5 &&
	app_installed_full test_app2 &&
	app_installed_full test_app3 &&
	app_installed_full test_app4 &&
	app_installed_full test_app5 &&
	move_data_to_yaffs.sh test_app3 &&
	app_installed_with_symlinks "$TEST_APP" &&
	app_installed_full test_app2 &&
	app_installed_with_symlinks test_app3 &&
	app_installed_full test_app4 &&
	app_installed_full test_app5
'

test_expect_success 'Specify multiple apps on command line works' '
	app_installed_full test_app2 &&
	app_installed_with_symlinks test_app3 &&
	app_installed_full test_app4 &&
	app_installed_full test_app5 &&
	move_data_to_yaffs.sh test_app2 test_app4 &&
	app_installed_with_symlinks test_app2 &&
	app_installed_with_symlinks test_app3 &&
	app_installed_with_symlinks test_app4 &&
	app_installed_full test_app5
'

test_expect_success 'Specify multiple apps already moved' '
	app_installed_with_symlinks test_app2 &&
	app_installed_with_symlinks test_app3 &&
	app_installed_with_symlinks test_app4 &&
	app_installed_full test_app5 &&
	move_data_to_yaffs.sh test_app2 test_app4 &&
	app_installed_with_symlinks test_app2 &&
	app_installed_with_symlinks test_app3 &&
	app_installed_with_symlinks test_app4 &&
	app_installed_full test_app5
'
test_expect_success 'Works with mix of symlinked/non-symlinked apps' '
	move_data_to_yaffs.sh &&
	app_installed_with_symlinks test_app5
'

test_expect_success 'Cleanup removed app works' '
	uninstall_app test_app3 &&
	test ! -d "$MDTY_DATADATA/test_app3" &&
	test -d "$MDTY_YAFFS/test_app3" &&
	move_data_to_yaffs.sh &&
	test ! -d "$MDTY_YAFFS/test_app3"
'

test_done
