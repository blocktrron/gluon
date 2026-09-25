'use strict';

import * as libubus from 'ubus';

let ubus = libubus.connect();

function http_error(status, message) {
	// ToDo: Map error codes
	print('Content-Type: text/plain', '\r\n');
	print('Status 500: Internal Server Error', '\r\n\r\n');
	print(message, '\r\n');
}

function http_object(ret_obj) {
	print('Content-Type: application/json', '\r\n');
	print('Status 200: OK', '\r\n\r\n');
	print(ret_obj);
}

export function query_ubus(ubus_object, ubus_method, params) {
	try {
		let ret_value = ubus.call(ubus_object, ubus_method, params);
		http_object(ret_value);
	} catch (error) {
		http_error(500, 'failed to query ubus');
		return;
	}
};