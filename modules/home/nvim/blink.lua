vim.schedule(function()
	vim.keymap.set("i", "<Tab>", function()
		local blink = require("blink.cmp")
		if blink.is_visible() then
			blink.accept()
		else
			return "\t"
		end
	end, { expr = true, silent = true, noremap = true, desc = "blink accept" })
end)
