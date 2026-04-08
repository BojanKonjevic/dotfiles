require("diffview").setup({
	enhanced_diff_hl = true,
	view = {
		default = { layout = "diff2_horizontal" },
		merge_tool = { layout = "diff3_horizontal" },
	},
	keymaps = {
		view = {
			{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
		},
		file_panel = {
			{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
		},
		file_history_panel = {
			{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
		},
	},
})
