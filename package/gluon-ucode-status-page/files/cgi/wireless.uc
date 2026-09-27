#!/usr/bin/ucode
import * as status_page from 'gluon.status-page';

function filter_object(ubus_object) {
	for (let record in ubus_object.history) {
		for (let phy_idx in record.output) {
			let out_interfaces = {};
			for (let interface_key in record.output[phy_idx].interfaces) {
				if (!match(interface_key, /^mesh[0-9]*/) && !match(interface_key, /^client[0-9]*/) && !match(interface_key, /^owe[0-9]*/))
					continue;

				out_interfaces[interface_key] = record.output[phy_idx].interfaces[interface_key];
				out_interfaces[interface_key].station_count = length(out_interfaces[interface_key].stations);
				if (!match(interface_key, /^mesh[0-9]*/))
					out_interfaces[interface_key].stations = [];
			}
			record.output[phy_idx].interfaces = out_interfaces;
		}
	}

	return ubus_object; // Placeholder implementation
}

status_page.query_ubus('gluon.statistics.wireless', 'get_statistics_history', null, filter_object);
