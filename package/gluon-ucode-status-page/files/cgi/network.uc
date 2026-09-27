#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

function filter_object(ubus_object) {
	let restricted_keys = ['br-wan'];
	let out_obj = {};
	for (let key in ubus_object) {
		if (key in restricted_keys) {
			continue;
		}

		// Take Information from the most recent history event.
		// Aggregate statistics
		let iface_output = {};
		let history = ubus_object[key]['history'];
		let newest_output = history[length(history) - 1]['output'];

		if (newest_output['type'] == 'wireless') {
			if (!match(key, /^mesh[0-9]*/) && !match(key, /^client[0-9]*/) && !match(key, /^owe[0-9]*/))
				continue;
		}

		iface_output['output'] = newest_output;

		iface_output['statistics'] = [];
		for (let snapshot in history) {
			let statistics_object = {
				'timestamp': snapshot['timestamp'],
				'statistics': snapshot['output']['statistics']
			};
			push(iface_output['statistics'], statistics_object);
		}

		
		out_obj[key] = iface_output;
	}
	return out_obj; // Placeholder implementation
}

status_page.query_ubus('gluon.statistics.network', 'get_statistics_history', null, filter_object);
