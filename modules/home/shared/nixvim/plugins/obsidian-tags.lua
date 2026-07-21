local vault_path = vim.fn.expand("~/Documents/Obsidian")
local tags_file = vault_path .. "/Tags.md"
local ns = vim.api.nvim_create_namespace("obsidian_tags")

local function load_allowed_tags()
	local allowed = {}
	local f = io.open(tags_file, "r")
	if not f then
		return allowed
	end
	for line in f:lines() do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed ~= "" and not trimmed:match("^#") then
			local tag = trimmed:match("^([%w%-_/]+)$")
			if tag then
				allowed[tag] = true
			end
		end
	end
	f:close()
	return allowed
end

-- Returns a list of { tag, lnum, col_start, col_end } for every tag occurrence,
-- covering YAML frontmatter and inline #tags, skipping fenced code blocks.
local function find_tags(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local occurrences = {}
	local in_frontmatter = false
	local in_code_block = false

	for i, line in ipairs(lines) do
		local lnum = i - 1
		if i == 1 and line:match("^%-%-%-%s*$") then
			in_frontmatter = true
		elseif in_frontmatter and line:match("^%-%-%-%s*$") then
			in_frontmatter = false
		elseif in_frontmatter then
			local s, e, inline = line:find("^tags:%s*%[(.-)%]")
			if inline then
				local pos = s
				for tag in inline:gmatch("[%w%-_/]+") do
					local ts, te = line:find(tag, pos, true)
					table.insert(occurrences, { tag = tag, lnum = lnum, col_start = ts - 1, col_end = te })
					pos = te + 1
				end
			end
			local ls, le, listitem = line:find("^%s*-%s*([%w%-_/]+)%s*$")
			if listitem and lines[i - 1] and lines[i - 1]:match("^tags:%s*$") then
				local ts, te = line:find(listitem, 1, true)
				table.insert(occurrences, { tag = listitem, lnum = lnum, col_start = ts - 1, col_end = te })
			end
		else
			if line:match("^```") then
				in_code_block = not in_code_block
			elseif not in_code_block then
				for ts, tag, te in line:gmatch("()#([%w%-_/]+)()") do
					table.insert(occurrences, { tag = tag, lnum = lnum, col_start = ts - 1, col_end = te - 1 })
				end
			end
		end
	end

	return occurrences
end

local function validate(bufnr)
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if not vim.startswith(filepath, vault_path) or filepath == tags_file then
		vim.diagnostic.reset(ns, bufnr)
		return
	end

	local allowed = load_allowed_tags()
	local occurrences = find_tags(bufnr)
	local diagnostics = {}

	for _, occ in ipairs(occurrences) do
		if not allowed[occ.tag] then
			table.insert(diagnostics, {
				lnum = occ.lnum,
				col = occ.col_start,
				end_col = occ.col_end,
				severity = vim.diagnostic.severity.WARN,
				message = "Unknown tag: #" .. occ.tag .. " (add to Tags.md if intentional)",
				source = "obsidian-tags",
			})
		end
	end

	vim.diagnostic.set(ns, bufnr, diagnostics)
end

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "BufEnter" }, {
	pattern = "*.md",
	callback = function(args)
		validate(args.buf)
	end,
})
