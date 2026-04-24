require("grug-far").setup({
	headerMaxWidth = 80,
	resultsSeparatorLineChar = "─",
	spinnerStates = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
	keymaps = {
		replace = { n = "<leader>r" },
		qflist = { n = "<leader>q" },
		syncLocations = { n = "<leader>s" },
		syncLine = { n = "<leader>l" },
		close = { n = "q" },
		historyOpen = { n = "<leader>h" },
		historyAdd = { n = "<leader>H" },
		refresh = { n = "<leader>R" },
		gotoLocation = { n = "<enter>" },
		pickHistoryEntry = { n = "<enter>" },
		abort = { n = "<leader>a" },
		toggleShowRgsInfo = { n = "<leader>i" },
		openLocation = { n = "<leader>o" },
	},
	engines = {
		ripgrep = {
			extraArgs = "--smart-case",
		},
	},
})
