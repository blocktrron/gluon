import * as fs from 'fs';
import * as rtnl from 'rtnl';

function arrayContains(arr, value) {
	return index(arr, value) != -1;
}

function readInterfaceProperty(ifname, property) {
	return trim(fs.readfile('/sys/class/net/' + ifname + '/' + property));
}

function readInterfacePropertyNum(ifname, property) {
	return int(readInterfaceProperty(ifname, property));
}

function getInterfaceType(properties) {
	if (arrayContains(properties, 'phy80211')) {
		/* ToDo: wireless-client wireless-mesh wireless-unknown */
		return 'wireless';
	} else if (arrayContains(properties, 'bridge')) {
		return 'bridge';
	} else if (arrayContains(properties, 'device')) {
		return 'wired';
	} else {
		return 'unknown';
	}
}

function getInterfaceAddress() {
	let interfaces = {};
	let response = rtnl.request(rtnl.const.RTM_GETADDR, rtnl.const.NLM_F_DUMP, {});

	for (let entry in response) {
		let ifname = entry['dev'];
		let address = entry['address'];
		let valid = entry['cacheinfo']['valid'];
		let preferred = entry['cacheinfo']['preferred'];
		let family = 'ipv6';
		if (entry['family'] == 2)
			family = 'ipv4';
		
		if (!(ifname in interfaces)) {
			interfaces[ifname] = [];
		}
		push(interfaces[ifname], {
			"address": address,
			"valid": valid,
			"preferred": preferred,
			"family": family
		});
	}
	return interfaces;
}


function render_func() {
	const interfaceList = fs.lsdir('/sys/class/net');
	let output = {};


	for (let ifname in interfaceList) {
		let interfaceInfo = {
			'addresses': []
		};
		let properties = fs.lsdir('/sys/class/net/' + ifname);
		let interfaceAddress = getInterfaceAddress();

		interfaceInfo['type'] = getInterfaceType(properties);
		if (arrayContains(properties, 'address')) {
			interfaceInfo['address'] = readInterfaceProperty(ifname, 'address');
		}

		if (arrayContains(properties, 'mtu')) {
			interfaceInfo['mtu'] = readInterfacePropertyNum(ifname, 'mtu');
		}

		if (arrayContains(properties, 'carrier')) {
			interfaceInfo['carrier'] = readInterfacePropertyNum(ifname, 'carrier') == 1;
		}

		if (arrayContains(properties, 'carrier_changes')) {
			interfaceInfo['carrier_changes'] = readInterfacePropertyNum(ifname, 'carrier_changes');
		}

		if (arrayContains(properties, 'speed')) {
			interfaceInfo['speed'] = readInterfacePropertyNum(ifname, 'speed');
		}

		if (arrayContains(properties, 'duplex')) {
			interfaceInfo['duplex'] = readInterfaceProperty(ifname, 'duplex');
		}

		let statistics = {
			"rx" : {
				"bytes": readInterfacePropertyNum(ifname, 'statistics/rx_bytes'),
				"packets": readInterfacePropertyNum(ifname, 'statistics/rx_packets')
			},
			"tx" : {
				"bytes": readInterfacePropertyNum(ifname, 'statistics/tx_bytes'),
				"packets": readInterfacePropertyNum(ifname, 'statistics/tx_packets')
			}
		};

		interfaceInfo['statistics'] = statistics;
		if (ifname in interfaceAddress) {
			interfaceInfo['addresses'] = interfaceAddress[ifname];
		}
		output[ifname] = interfaceInfo;
	}
	return output;
}

return { 'render': render_func };