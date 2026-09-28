import * as nl80211 from 'nl80211';

import * as gluon_util from 'gluon.native.util';

function get_survey(ifindex) {
	let output = [];
	let survey = nl80211.request(nl80211.const.NL80211_CMD_GET_SURVEY, nl80211.const.NLM_F_DUMP, { dev: ifindex });

	for (let survey_entry in survey) {
		push(output, survey_entry.survey_info);
	}
	return output;
}

function iftype_to_string(iftype) {
	if (iftype === nl80211.const.NL80211_IFTYPE_STATION) {
		return "station";
	} else if (iftype === nl80211.const.NL80211_IFTYPE_AP) {
		return "ap";
	} else if (iftype === nl80211.const.NL80211_IFTYPE_MESH_POINT) {
		return "mesh_point";
	}

	return "unknown";
}

function channel_width_to_mhz(channel_width) {
	switch (channel_width) {
		case 0: /* 20 NoHT */
			return 20;
		case 1: /* HT20 */
			return 20;
		case 2: /* HT40 */
			return 40;
		case 3: /* HT80 */
			return 80;
		case 4: /* HT80+80 */
			return 160;
		case 5: /* HT160 */
			return 160;
		case 6: /* HT5 */
			return 5;
		case 7: /* HT10 */
			return 10;
		default:
			return 0;
	}
}

export function get_interface_stations(ifname) {
	/* Request all Stations */
	let output = [];
	let stations = nl80211.request(nl80211.const.NL80211_CMD_GET_STATION, nl80211.const.NLM_F_DUMP, { dev: ifname });
	for (let station in stations) {
		let sta_obj = {
			"mac": station.mac,
			"signal": station.sta_info.signal,
			"tx_rate": station.sta_info.tx_bitrate.bitrate32 * 100,
			"rx_rate": station.sta_info.rx_bitrate.bitrate32 * 100,
			"tx_bytes": station.sta_info.tx_bytes64,
			"rx_bytes": station.sta_info.rx_bytes64,
			"tx_packets": station.sta_info.tx_packets,
			"rx_packets": station.sta_info.rx_packets,
			"tx_retries": station.sta_info.tx_retries,
			"tx_failed": station.sta_info.tx_failed,
			"expected_throughput": station.sta_info.expected_throughput,
			"connected_time": station.sta_info.connected_time,
			"inactive_time": station.sta_info.inactive_time,
		};
		push(output, sta_obj);
	}
	return output;
};

export function get_interfaces() {
	let output = [];
	let interfaces = nl80211.request(nl80211.const.NL80211_CMD_GET_INTERFACE, nl80211.const.NLM_F_DUMP, {});
	for (let iface in interfaces) {
		let iface_data = {
			"name": iface.ifname,
			"idx": gluon_util.if_nametoindex(iface.ifname),
			"type": iftype_to_string(iface.iftype),
			"mac": iface.mac,
			"wiphy": iface.wiphy,
			"frequency": {
				"frequency": iface.wiphy_freq,
				"channel_width_mhz": channel_width_to_mhz(iface.channel_width)
			},
		};

		push(output, iface_data);
	}
	return output;
};

export function get_wireless_state() {
	let phys_out = {};

	/* Dump all PHYs */
	let wireless_phys = nl80211.request(nl80211.const.NL80211_CMD_GET_WIPHY, nl80211.const.NLM_F_DUMP, {});

	for (let phy in wireless_phys) {
		phys_out[phy.wiphy] = {
			"idx": phy.wiphy,
			"name": phy.wiphy_name,
			"interfaces": {}
		};
	}

	/* Map all interfaces */
	let interfaces = get_interfaces();
	for (let iface in interfaces) {
		if (!phys_out[iface.wiphy])
			continue;

		/* Get Station information for this interface */
		let stations = get_interface_stations(iface.name);
		iface.stations = stations;
		phys_out[iface.wiphy].interfaces[iface.name] = iface;
	}

	/* Request Survey for the first interface of each PHY */
	for (let phy in phys_out) {
		let interfaces = phys_out[phy].interfaces;
		for (let ifname in interfaces) {
			phys_out[phy].survey = get_survey(interfaces[ifname].idx);
			break;
		}
	}

	return phys_out;
};