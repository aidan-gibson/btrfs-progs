#!/bin/bash

source "$TEST_TOP/common"
source "$TEST_TOP/common.convert"

check_prereq btrfs-convert
check_global_prereq mke2fs

setup_root_helper
prepare_test_dev

# Iterate over defaults and options that are not tied to hardware capabilities
# or number of devices
for feature in '' 'block-group-tree' ; do
	convert_test ext2 "$feature" "ext2 4k nodesize" 4096 mke2fs -b 4096
	convert_test ext2 "$feature" "ext2 8k nodesize" 8192 mke2fs -b 4096
	convert_test ext2 "$feature" "ext2 16k nodesize" 16384 mke2fs -b 4096
	convert_test ext2 "$feature" "ext2 32k nodesize" 32768 mke2fs -b 4096
	convert_test ext2 "$feature" "ext2 64k nodesize" 65536 mke2fs -b 4096
done
