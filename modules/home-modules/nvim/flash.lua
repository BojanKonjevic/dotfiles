require("flash").setup({
	labels = "asdfghjklqwertyuiopzxcvbnm",
	search = {
		multi_window = true,
	},
	jump = {
		autojump = true,
	},
})
vim.keymap.set({ "n", "x", "o" }, "f", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function()
	require("flash").remote()
end, { desc = "Remote Flash" })
