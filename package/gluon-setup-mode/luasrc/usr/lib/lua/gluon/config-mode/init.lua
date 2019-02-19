local io = io
local math = math
local string = string

local bit = require 'bit'

module 'gluon.config-mode'

function get_random_mac()
	local urandom = io.open('/dev/urandom', 'r')
	local seed1, seed2 = urandom:read(2):byte(1, 2)
	math.randomseed(seed1*0x100 + seed2)
	urandom:close()

	first_octet = math.random(0, 255)
	first_octet = bit.bor(first_octet, 0x02)  -- set locally administered bit
	first_octet = bit.band(first_octet, 0xFE) -- unset the multicast bit

	mac = string.format('%02x', first_octet)
	for var=0,5 do
		mac = mac .. ":" .. string.format('%02x', math.random(0, 255))
	end
	return mac
end
