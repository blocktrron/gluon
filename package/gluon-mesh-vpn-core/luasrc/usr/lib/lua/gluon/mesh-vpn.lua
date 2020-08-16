local uci = require('simple-uci').cursor()

local util = require 'gluon.util'

local M = {}

function M.enabled()
	return uci:get_bool('gluon', 'mesh_vpn', 'enabled')
end

function M.enable(val)
	return uci:set('gluon', 'mesh_vpn', 'enabled', val)
end

function M.get_interface()
	return 'mesh-vpn'
end

function M.get_proto(name)
	return require('gluon.mesh-vpn.proto.' .. name)
end

function M.get_proto_names()
	local out = {}

	for _, v in ipairs(util.glob('/lib/gluon/mesh-vpn/proto/*')) do
		table.insert(out, v:match('([^/]+)$'))
	end

	return out
end

function M.get_active_proto()
	-- Active proto is the proto in use by the currently
	-- active site / domain

	for _, name in ipairs(M.get_proto_names()) do
		local proto = M.get_proto(name)
		if proto.active() then
			return name, proto
		end
	end

	return nil, nil
end

return M
