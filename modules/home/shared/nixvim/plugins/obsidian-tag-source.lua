local source = {}
source.new = function()
	return setmetatable({}, { __index = source })
end

function source:get_trigger_characters()
	return { "#" }
end

function source:get_completions(ctx, callback)
	local vault_path = vim.fn.expand("~/Documents/Obsidian")
	local tags_file = vault_path .. "/Tags.md"
	local items = {}

	local f = io.open(tags_file, "r")
	if f then
		for line in f:lines() do
			local trimmed = line:match("^%s*(.-)%s*$")
			if trimmed ~= "" and not trimmed:match("^#") then
				local tag = trimmed:match("^([%w%-_/]+)$")
				if tag then
					table.insert(items, {
						label = "#" .. tag,
						insertText = tag,
						kind = require("blink.cmp.types").CompletionItemKind.Text,
					})
				end
			end
		end
		f:close()
	end

	callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return source
