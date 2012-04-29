#!/bin/sh
#
# Copyright (c) 2012 Brandon Casey
#

test_description='Initialization of /data/data handled correctly'

. ./test-lib.sh

test_expect_success 'Setup worked correctly' '
	for app in $TEST_APP $MDTY_SKIP_APPS; do
		app_installed_full "$app" || return 1
	done
'

test_done
