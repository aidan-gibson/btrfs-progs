#!/bin/bash
# Verify mkfs for zoned devices support block-group-tree feature

source "$TEST_TOP/common" || exit

setup_root_helper
prepare_test_dev

nullb="$TEST_TOP/nullb"
# Create one 128M device with 4M zones, 32 of them
size=128
zone=4

run_mayfail $SUDO_HELPER "$nullb" setup
if [ $? != 0 ]; then
	_not_run "cannot setup nullb environment for zoned devices"
fi

# Record any other pre-existing devices in case creation fails
run_check $SUDO_HELPER "$nullb" ls

# Last line has the name of the device node path
out=$(run_check_stdout $SUDO_HELPER "$nullb" create -s "$size" -z "$zone")
if [ $? != 0 ]; then
	_fail "cannot create nullb zoned device $i"
fi
dev=$(echo "$out" | tail -n 1)
name=$(basename "${dev}")

run_check $SUDO_HELPER "$nullb" ls

TEST_DEV="${dev}"
last_zone_sector=$(( 4 * 31 * 1024 * 1024 / 512 ))
# Write some data to the last zone
run_check $SUDO_HELPER dd if=/dev/urandom of="${dev}" bs=1M count=4 seek=$(( 4 * 31 ))
# Use single as it's supported on more kernels
run_check $SUDO_HELPER "$TOP/mkfs.btrfs" -f -m single -d single "${dev}"
# Check if the lat zone is empty
$SUDO_HELPER blkzone report -o ${last_zone_sector} -c 1 "${dev}" | grep -Fq '(em)'
if [ $? != 0 ]; then
	_fail "last zone is not empty"
fi

# Write some data to the last zone
run_check $SUDO_HELPER dd if=/dev/urandom of="${dev}" bs=1M count=1 seek=$(( 4 * 31 ))
# Create a FS excluding the last zone
run_mayfail $SUDO_HELPER "$TOP/mkfs.btrfs" -f -b $(( 4 * 31 ))M -m single -d single "${dev}"
if [ $? == 0 ]; then
	_fail "mkfs.btrfs should detect active zone outside of FS range"
fi

# Fill the last zone to finish it
run_check $SUDO_HELPER dd if=/dev/urandom of="${dev}" bs=1M count=3 seek=$(( 4 * 31 + 1 ))
# Create a FS excluding the last zone
run_mayfail $SUDO_HELPER "$TOP/mkfs.btrfs" -f -b $(( 4 * 31 ))M -m single -d single "${dev}"
# Check if the lat zone is not empty
$SUDO_HELPER blkzone report -o ${last_zone_sector} -c 1 "${dev}" | grep -Fq '(em)'
if [ $? == 0 ]; then
	_fail "last zone is empty"
fi

run_check $SUDO_HELPER "$nullb" rm "${name}"
