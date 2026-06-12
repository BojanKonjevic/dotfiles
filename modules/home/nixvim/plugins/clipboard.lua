if vim.env.SSH_CONNECTION then
	local function base64(text)
		if vim.base64 then
			return vim.base64.encode(text)
		end
		return vim.encode_base64(text)
	end

	local function copy(lines, _)
		local seq = ("\027]52;c;%s\027\\"):format(base64(table.concat(lines, "\n")))
		pcall(vim.api.nvim_call_function, "chansend", { vim.api.nvim_get_vvar("stderr"), seq })
	end

	vim.g.clipboard = {
		name = "OSC52",
		copy = {
			["+"] = copy,
			["*"] = copy,
		},
		paste = {
			["+"] = function()
				return {}
			end,
			["*"] = function()
				return {}
			end,
		},
	}
end
