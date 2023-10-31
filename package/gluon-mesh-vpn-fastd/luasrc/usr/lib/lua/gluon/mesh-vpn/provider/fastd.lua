local uci = require('simple-uci').cursor()

local site = require 'gluon.site'
local util = require 'gluon.util'
local vpn_core = require 'gluon.mesh-vpn'

local M = {}

function M.public_key()
	local key = util.trim(util.exec('/etc/init.d/fastd show_key mesh_vpn'))

	if key == '' then
		key = nil
	end

	return key
end

function M.enable(val)
	uci:set('fastd', 'mesh_vpn', 'enabled', val)
	uci:save('fastd')
end

function M.active()
	return site.mesh_vpn.fastd() ~= nil
end

function M.set_limit(ingress_limit, egress_limit)
	-- ToDo v2025.1.x: Remove legacy simple-tc
	uci:delete('simple-tc', 'mesh_vpn')
	uci:save('simple-tc')

	if ingress_limit ~= nil and egress_limit ~= nil then
		uci:section('sqm', 'queue', 'mesh_vpn', {
			interface = vpn_core.get_interface(),
			enabled = true,
			upload = egress_limit,
			download = ingress_limit,
			qdisc = 'cake',
			script = 'piece_of_cake.qos',
			debug_logging = '0',
			verbosity = '5',
		})
	end

	uci:save('sqm')
end

function M.mtu()
	return site.mesh_vpn.fastd.mtu()
end

return M
