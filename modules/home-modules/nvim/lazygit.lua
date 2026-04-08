local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
	cmd = "lazygit",
	direction = "float",
	float_opts = {
		border = "rounded",
		width = math.floor(vim.o.columns * 0.92),
		height = math.floor(vim.o.lines * 0.82),
	},
	hidden = true,
	on_open = function(term)
		vim.keymap.set("t", "<C-g>", function()
			term:toggle()
		end, { buffer = term.bufnr })
	end,
})
vim.keymap.set("n", "<C-g>", function()
	lazygit:toggle()
end, { desc = "Toggle Lazygit" })
