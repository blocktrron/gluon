{%
import * as fs from 'fs';

import * as gluon_system from 'gluon.native.system';
import * as gluon_platform from 'gluon.native.platform';
import * as gluon_util from 'gluon.native.util';
import * as pretty_hostname from 'gluon.pretty-hostname';

function strip_newline(str) {
	return replace(str, '\n', '');
}

function gluon_version() {
	let version_str = strip_newline(fs.readfile('/lib/gluon/gluon-version'));
	return 'gluon-' + version_str;
}

function render_func() {
	let sysinfo = gluon_system.sysinfo();
	let site = gluon_util.get_site_config();
	let board = gluon_platform.board();

	let return_object = {
		"node_id": gluon_util.get_node_id(),
		"hostname": pretty_hostname.get(),
		"hardware": {
			"model": board['model'],
			"nproc": gluon_system.nproc(),
		},
		"network": {
			"mac": gluon_util.get_sysconfig("primary_mac"),
		},
		"software": {
			"firmware": {
				"base": gluon_version(),
				"release": strip_newline(fs.readfile('/lib/gluon/release')),
				"target": board['target'],
				"subtarget": board['subtarget'],
				"image_name": board['image_name'],
			},
		},
		"system": {
			"site_code": site['site_code'],
		}
	};

	if (gluon_util.has_domains()) {
		return_object["system"]["domain_code"] = gluon_util.get_domain();
		return_object["system"]["primary_domain_code"] = gluon_util.get_primary_domain();
	}

	return return_object;
}

return { 'render': render_func };
