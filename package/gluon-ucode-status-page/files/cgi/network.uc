#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';



function skip_iface(ifname, ifdata) {
	let restricted_keys = [
		'br-wan', /* Contains WAN / Private WiFi information */
		'dummy0', /* Batadv MAC / no counters */
		'lo', /* Loopback interface */
		'local-port', /* Local port interface - Read from local-node */
		'primary0' /* batadv MAC / no counters */
	];

	if (ifname in restricted_keys)
		return true;

	if (ifdata.type == 'wireless') {
		if (!match(ifname, /^mesh[0-9]*/) && !match(ifname, /^client[0-9]*/) && !match(ifname, /^owe[0-9]*/))
			return true;
	}

	return false;
}

function filter_object(ubus_object) {
	let iface_output = {};

	/* Extract interface info from newest output */
	let newest_output = ubus_object['history'][length(ubus_object['history']) - 1]['output'];
	for (let ifname in newest_output) {
			let iface_object = newest_output[ifname];
			if (skip_iface(ifname, iface_object))
				continue;

			iface_output[ifname] = {
				'output': iface_object,
				'statistics': []
			};
	}

	/* Traverse entire history to build statistics history */
	for (let record in ubus_object['history']) {
		let timestamp = record['timestamp'];
		for (let ifname in record['output']) {
			if (skip_iface(ifname, record['output'][ifname]))
				continue;

			let statistics_object = {
				'timestamp': timestamp,
				'statistics': record['output'][ifname]['statistics']
			};
			push(iface_output[ifname]['statistics'], statistics_object);
		}
	}

	return iface_output; // Placeholder implementation
}

status_page.query_ubus('gluon.statistics.network', 'get_statistics_history', null, filter_object);
