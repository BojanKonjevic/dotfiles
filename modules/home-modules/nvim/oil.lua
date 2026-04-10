require("oil").setup({
	default_explorer = true,
	delete_to_trash = true,
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
