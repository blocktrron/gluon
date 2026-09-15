import * as gluon_system from 'gluon.native.system';
import * as gluon_platform from 'gluon.native.platform';
import * as gluon_util from 'gluon.native.util';
import * as pretty_hostname from 'gluon.pretty-hostname';

import * as fs from 'fs';

function strip_newline(str) {
	return replace(str, '\n', '');
}

function gluon_version() {
	let version_str = strip_newline(fs.readfile('/lib/gluon/gluon-version'));
	return 'gluon-' + version_str;
}

function render_func() {
	let sysinfo = gluon_system.sysinfo();
	let site_config = gluon_util.get_site_config();
	let board = gluon_platform.board();

	let return_object = {
		"hostname": pretty_hostname.get(),
		"board": gluon_platform.board(),
		"memory": {
			"total": sysinfo.totalram,
			"free": sysinfo.freeram,
			"shared": sysinfo.sharedram,
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
		"site": {
			"domain_code": gluon_util.get_domain(),
			"domain_name": "PRETTY NAMES GO HERE",
			"primary_domain_code": gluon_util.get_primary_domain(),
		},
		"load": sysinfo.loads,
		"uptime": sysinfo.uptime,
		"processors": gluon_system.nproc(),
		"processes": sysinfo.procs,
	};

	if (site_config['site_code'] != null)
		return_object['site']['site_code'] = site_config['site_code'];

	return return_object;
}

return { 'render': render_func };