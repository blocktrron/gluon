local platform = require 'gluon.platform'


local M = {}

function M.get_custom_led()
	if platform.match('ath79', 'generic', {
		'ubnt,unifi-ap-pro',
		'ubnt,unifiac-pro',
	})
	then
		return "ubnt:green:led"
	end
	return nil
end

return M
