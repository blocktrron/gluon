local uci = require("simple-uci").cursor()
local util = require 'gluon.util'
local platform = require 'gluon.platform'

-- where to read the configuration from
local primary_iface = 'wan_radio0'

local f = Form(translate("Private WLAN"))

local s = f:section(Section, nil, translate(
	'Your node can additionally extend your private network by bridging the WAN interface '
	.. 'with a separate WLAN. This feature is completely independent of the mesh functionality. '
	.. 'Please note that the private WLAN and meshing on the WAN interface should not be enabled '
	.. 'at the same time.'
))

local enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = uci:get('wireless', primary_iface) and not uci:get_bool('wireless', primary_iface, "disabled")

local ssid = s:option(Value, "ssid", translate("Name (SSID)"))
ssid:depends(enabled, true)
ssid.datatype = "maxlength(32)"
ssid.default = uci:get('wireless', primary_iface, "ssid")

local key = s:option(Value, "key", translate("Key"), translate("8-63 characters"))
key:depends(enabled, true)
key.datatype = "wpakey"
key.default = uci:get('wireless', primary_iface, "key")

local encryption = s:option(ListValue, "encryption", translate("Encryption"))
encryption:depends(enabled, true)
encryption:value("psk2", translate("WPA2"))
if platform.supports_wpa3(uci) then
	encryption:value("psk3-mixed", translate("WPA2 / WPA3"))
	encryption:value("psk3", translate("WPA3"))
end
encryption.default = uci:get('wireless', primary_iface, 'encryption') or "psk2"

function f:write()
	util.foreach_radio(uci, function(radio, index)
		local radio_name = radio['.name']
		local name   = "wan_" .. radio_name

		local pmf = 0

		if platform.supports_wpa3(uci) then
			if encryption.data == "psk3" then
				pmf = 2
			elseif encryption.data == "psk3-mixed" then
				pmf = 1
			end
		end

		if enabled.data then
			local macaddr = util.get_wlan_mac(uci, radio, index, 4)

			uci:section('wireless', "wifi-iface", name, {
				device     = radio_name,
				network    = "wan",
				mode       = 'ap',
				encryption = encryption.data,
				ieee80211w = pmf,
				ssid       = ssid.data,
				key        = key.data,
				macaddr    = macaddr,
				disabled   = false,
			})
		else
			uci:set('wireless', name, "disabled", true)
		end
	end)

	uci:commit('wireless')
end

return f
