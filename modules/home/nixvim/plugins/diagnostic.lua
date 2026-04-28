require("tiny-inline-diagnostic").setup({
	preset = "modern",
	transparent_bg = true,
	transparent_cursorline = true,
	signs = {
		arrow = "  ",
	},
	hi = {
		error = "DiagnosticError",
		warn = "DiagnosticWarn",
		info = "DiagnosticInfo",
		hint = "DiagnosticHint",
	},
	mixing_color = "None",
})
vim.diagnostic.config({ virtual_text = false })
