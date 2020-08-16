local uci = require("simple-uci").cursor()

local util = require "gluon.util"

local M = {}

function M.enabled()
	return uci:get_bool("gluon", "mesh_vpn", "enabled")
end

function M.enable(val)
	return uci:set("gluon", "mesh_vpn", "enabled", val)
end

function M.get_interface()
	return 'mesh-vpn'
end

function M.get_method(name)
	return require("gluon.mesh-vpn.method." .. name)
end

function M.get_method_names()
	local out = {}

	for _, v in ipairs(util.glob("/lib/gluon/mesh-vpn/method/*")) do
		table.insert(out, v:match('([^/]+)$'))
	end

	return out
end

function M.get_active_method_name()
	for _, name in ipairs(M.get_method_names()) do
		local method = M.get_method(name)

		if method.available() then
			return name
		end
	end

	return nil
end

function M.get_inactive_method_names()
	local inactive_methods = {}

	for _, name in ipairs(M.get_method_names()) do
		local method = M.get_method(name)

		if not method.available() then
			table.insert(inactive_methods, name)
		end
	end

	return inactive_methods
end

function M.get_active_method()
	local name = M.get_active_method_name()

	if name ~= nil then
		return M.get_method(name)
	end

	return nil
end

function M.get_inactive_methods()
	local methods = {}

	for _, name in ipairs(M.get_inactive_method_names()) do
		table.insert(methods, M.get_method(name))
	end

	return methods
end

return M
