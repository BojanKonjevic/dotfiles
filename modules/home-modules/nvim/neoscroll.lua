require("neoscroll").setup({
	mappings = {},
	hide_cursor = true,
	stop_eof = true,
	respect_scrolloff = true,
	cursor_scrolls_alone = false,
	duration_multiplier = 0.8,
	easing = "cubic",
})
vim.keymap.set("n", "<ScrollWheelUp>", function()
	require("neoscroll").scroll(-5, { duration = 80, easing = "quadratic" })
end)
vim.keymap.set("n", "<ScrollWheelDown>", function()
	require("neoscroll").scroll(5, { duration = 80, easing = "quadratic" })
end)
vim.keymap.set("i", "<ScrollWheelUp>", function()
	require("neoscroll").scroll(-5, { duration = 80, easing = "quadratic" })
end)
vim.keymap.set("i", "<ScrollWheelDown>", function()
	require("neoscroll").scroll(5, { duration = 80, easing = "quadratic" })
end)
vim.keymap.set("n", "<leader>r", function()
	local file = vim.fn.expand("%:p")
	local term = require("toggleterm.terminal").Terminal:new({
		cmd = "python3 " .. vim.fn.shellescape(file),
		direction = "float",
		float_opts = {
			border = "rounded",
			width = math.floor(vim.o.columns * 0.92),
			height = math.floor(vim.o.lines * 0.82),
		},
		close_on_exit = false,
		auto_scroll = true,
	})
	term:toggle()
end, { desc = "[R]un Python file" })
