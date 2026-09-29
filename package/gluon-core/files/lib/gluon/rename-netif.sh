#!/bin/sh

RUN_TYPE="$1"

# ToDo: Ensure preinit can't invoke hotplug path
if [ "$RUN_TYPE" = "preinit" ]; then
	# Check if /etc/uci-defaults/zzz-gluon-upgrade exists.
	# Indicates this is an upgrade --> Backup old mappings
	# They might come handy down the road.
	if [ -f /etc/uci-defaults/zzz-gluon-upgrade ]; then
		mv /lib/gluon/core/renamed-interfaces /lib/gluon/core/renamed-interfaces.pre
	fi
fi

mkdir -p /lib/gluon/core/renamed-interfaces

OS_RELEASE="$(grep '^OPENWRT_ARCH=' /etc/os-release | cut -d '=' -f 2 | cut -d '"' -f 2)"
if ! echo "$OS_RELEASE" | grep -q "^x86"; then
	exit 0
fi

for DEVICENAME in $(ls /sys/class/net); do
	if ! echo "$DEVICENAME" | grep -q "^eth"; then
		continue
	fi

	DEV_PATH="/sys/class/net/$DEVICENAME"
	DEV_SUBSYS="$(readlink -f "$DEV_PATH/device/subsystem")"
	DEV_PHYSICAL_PATH="$(readlink -f "$DEV_PATH/device")"
	DEV_MACADDR="$(cat "$DEV_PATH/address")"
	DEVNAME_MACADDR="$(echo "$DEV_MACADDR" | tr -d ':')"

	# ToDo: Keep per-subsys mapping to address PCIe path?
	# This might be handy in case the Offloader is a VM and
	# the MAC address is random or the VM is migrated.
	# Can be addressed later. Keeping the current approach for now.
	if echo "$DEV_SUBSYS" | grep -q "/usb$"; then
		DEVICENAME_NEW="usb$DEVNAME_MACADDR"
	elif echo "$DEV_SUBSYS" | grep -q "/pci$"; then
		DEVICENAME_NEW="pci$DEVNAME_MACADDR"
	elif echo "$DEV_SUBSYS" | grep -q "/virtio$"; then
		DEVICENAME_NEW="vio$DEVNAME_MACADDR"
	else
		DEVICENAME_NEW="eth$DEVNAME_MACADDR"
	fi

	ip link set "$DEVICENAME" name "$DEVICENAME_NEW"

	# Write as much information about the rename action as possible.
	# This can help to forward-fix issues with device assignment after upgrades
	# (As we backup the old mappings)
	mkdir -p "/lib/gluon/core/renamed-interfaces/$DEVICENAME"
	echo -n "$DEVICENAME" > "/lib/gluon/core/renamed-interfaces/$DEVICENAME/name_original"
	echo -n "$DEVICENAME_NEW" > "/lib/gluon/core/renamed-interfaces/$DEVICENAME/name_new"
	echo -n "$DEV_MACADDR" > "/lib/gluon/core/renamed-interfaces/$DEVICENAME/macaddr"
	echo -n "$DEV_SUBSYS" > "/lib/gluon/core/renamed-interfaces/$DEVICENAME/subsystem"
	echo -n "$DEV_PHYSICAL_PATH" > "/lib/gluon/core/renamed-interfaces/$DEVICENAME/physical_path"
done
