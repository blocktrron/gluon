#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

function filter_object(ubus_object) {
	let restricted_keys = ['br-wan'];
	let out_obj = {};
	for (let key in ubus_object) {
		let iface_obj = ubus_object[key];
		if (key in restricted_keys) {
			continue;
		}

		if (iface_obj['type'] == 'wireless') {
			if (!match(key, /^mesh[0-9]*/) && !match(key, /^client[0-9]*/) && !match(key, /^owe[0-9]*/))
				continue;
		}
		out_obj[key] = ubus_object[key];
	}
	return out_obj; // Placeholder implementation
}

status_page.query_ubus('gluon.statistics.network', 'get_statistics', null, filter_object);
