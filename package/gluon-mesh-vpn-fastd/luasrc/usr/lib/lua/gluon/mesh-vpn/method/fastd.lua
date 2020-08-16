local uci = require("simple-uci").cursor()

local site = require 'gluon.site'
local util = require "gluon.util"

local M = {}

function M.public_key()
	return util.trim(util.exec("/etc/init.d/fastd show_key mesh_vpn"))
end

function M.enabled()
	return uci:get_bool("fastd", "mesh_vpn", "enabled")
end

function M.enable(val)
	uci:set("fastd", "mesh_vpn", "enabled", val)
	uci:save("fastd")
end

function M.available()
	return site.mesh_vpn.fastd() ~= nil
end

function M.set_limit(_, _)
	-- handled by simple-tc
	return nil
end

function M.uci_sections()
	return {"fastd"}
end

return M
