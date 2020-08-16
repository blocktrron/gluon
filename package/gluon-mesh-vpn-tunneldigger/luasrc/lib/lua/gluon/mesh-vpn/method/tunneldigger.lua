local uci = require("simple-uci").cursor()

local site = require 'gluon.site'

local M = {}

function M.public_key()
	return nil
end

function M.enabled()
	return uci:get_bool("tunneldigger", "mesh_vpn", "enabled")
end

function M.enable(val)
	uci:set("tunneldigger", "mesh_vpn", "enabled", val)
	uci:save("tunneldigger")
end

function M.available()
	return site.mesh_vpn.tunneldigger() ~= nil
end

function M.set_limit(ingress_limit, _)
	if ingress_limit ~= nil then
		uci:set("tunneldigger", "mesh_vpn", "limit_bw_down", ingress_limit)
	else
		uci:delete('tunneldigger', 'mesh_vpn', 'limit_bw_down')
	end
	uci:save("tunneldigger")
end

function M.uci_sections()
	return {"tunneldigger"}
end

return M
