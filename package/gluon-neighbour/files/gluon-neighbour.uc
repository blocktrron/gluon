#!/usr/bin/env ucode

import * as libubus from 'ubus';
import * as uloop from 'uloop';

import * as gluon_util from 'gluon.native.util';
import * as gluon_neighbour from 'gluon.native.neighbour';

const update_interval = 2500; // milliseconds
const node_id_self = gluon_util.get_node_id();

uloop.init();

let ubus = libubus.connect();
let update_timer;

let interfaces = {
	"mesh-vpn": {},
	"mesh0": {},
	"mesh1": {}
};

let neighbors = {};

function neighbor_save(iface, response_obj) {
	let node_id = response_obj['node_id'];
	if (!(node_id in neighbors)) {
		neighbors[node_id] = {'first_seen': 0, 'interfaces': [iface], 'response': {}};
	}
	neighbors[node_id]['response'][node_id] = response_obj;

}

function update_timer_run() {
	/* Try to create socket if it does not exist */
	for (let iface in interfaces) {
		if (!('query' in interfaces[iface])) {
			let query = gluon_neighbour.create(iface, 'ff02::2:1001');
			if (query != null)
				interfaces[iface]['query'] = query;
		}
	}

	/* Read pending responses */
	for (let iface in interfaces) {
		let responses = gluon_neighbour.read(interfaces[iface]['query']);
		for (let response in responses) {
			try {
				let response_obj = json(response);
				let node_id = response_obj['node_id'];
				if (node_id == node_id_self) {
					continue;
				}
				neighbor_save(iface, response_obj);
			} catch (e) {
				print('Error parsing neighbor data for interface ', iface, ' with response ', response, ': ', e, '\n');
			}
		}
	}

	/* Update all providers */
	for (let iface in interfaces) {
		/* Update each interface */
		gluon_neighbour.query(interfaces[iface]['query'], 'nodeinfo');
	}
	
	gc();
	update_timer.set(update_interval);
}

/* Detect all interfaces */
for (let iface in interfaces) {
	/* Need On-Link group here, not mesh-wide */
	let query = gluon_neighbour.create(iface, 'ff02::2:1001');
	if (query != null)
		interfaces[iface]['query'] = query;
}

/* Publish ubus object */
let ubus_methods = {
	'get_neighbours': {
		call: function(request, msg) {
			return neighbors;
		},
		args : {}
	},
};
ubus.publish('gluon.neighbour', ubus_methods);

/* Schedule update timer */
update_timer = uloop.timer(update_interval, update_timer_run);

/* Run the main loop */
uloop.run();
