local M = {}

local function collect_keys(t)
	local ret = {}
	for v in pairs(t) do
		table.insert(ret, v)
	end
	return ret
end

local function evaluate_device(files, env, dev)
	local selections = {}
	local funcs = {}
	local device_overrides = {}

	local function add_elements(element_type, element_list)
		for _, element in ipairs(element_list) do
			if not selections[element_type] then
				selections[element_type] = {}
			end

			selections[element_type][element] = true
		end
	end

	local function add_override(ovr_key, ovr_value)
		device_overrides[ovr_key] = ovr_value
	end

	function funcs.Features(features)
		add_elements('feature', features)
	end

	function funcs.Packages(packages)
		add_elements('package', packages)
	end

	function funcs.Broken(broken)
		assert(
			type(broken) == 'bool',
			'Incorrect use of Broken(): has to be a boolean value')
		add_override('broken', broken)
	end

	function funcs.Disable()
		add_override('disabled', true)
	end

	function funcs.Disavle_Factory()
		add_override('disable_factory', true)
	end

	function funcs.device(device_names)
		assert(
			type(device_names) == 'table',
			'Incorrect use of device(): pass a list of device-names as argument')

		for _, device_name in ipairs(device_names) do
			if device_name == dev.name then
				return true
			end
		end

		return false
	end

	function funcs.target(target, subtarget)
		assert(
			type(target) == 'string',
			'Incorrect use of target(): pass a target-name as first argument')

		if target ~= env.BOARD then
			return false
		end

		if subtarget and subtarget ~= env.SUBTARGET then
			return false
		end

		return true
	end

	function funcs.device_class(class)
		return dev.options.class == class
	end

	-- Evaluate the feature definition files
	for _, file in ipairs(files) do
		local f, err = loadfile(file)
		if not f then
			error('Failed to parse feature definition: ' .. err)
		end
		setfenv(f, funcs)
		f()
	end

	return {
		selections = selections,
		device_overrides = device_overrides,
	}
end

function M.get_selection(selection_type, files, env, dev)
	local eval_result = evaluate_device(files, env, dev)
	return collect_keys(eval_result.selections[selection_type] or {})
end

function M.device_overrides(files, env, dev)
	local eval_result = evaluate_device(files, env, dev)
	return eval_result.device_overrides
end

return M
