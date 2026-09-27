import * as gluon_nl80211 from 'gluon.nl80211';

function render_func() {
	let wireless_object = gluon_nl80211.get_wireless_state();

	return wireless_object;
}

return { 'render': render_func };