local M = {}

-- Function to get the relative path of the current buffer
local function get_relative_path()
	local absolute_path = vim.fn.expand("%:p")
	local current_dir = vim.fn.getcwd()
	local relative_path = vim.fn.fnamemodify(absolute_path, ":." .. current_dir .. ":~:.")
	return relative_path
end

-- Function to get visual selection line numbers
local function get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	return start_pos[2], end_pos[2] -- Return start and end line numbers
end

-- Function to create or get the frontier buffer
local function get_frontier_buffer()
	local frontier_bufnr = vim.fn.bufnr("frontier")
	if frontier_bufnr == -1 then
		-- Create a new buffer named 'frontier'
		vim.cmd("new frontier")
		frontier_bufnr = vim.fn.bufnr("frontier")

		-- Set buffer options
		vim.api.nvim_buf_set_option(frontier_bufnr, "buftype", "nofile")
		vim.api.nvim_buf_set_option(frontier_bufnr, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(frontier_bufnr, "swapfile", false)
	end
	return frontier_bufnr
end

-- Main function to save selection location
function M.save_selection_location()
	-- Get the relative path
	local relative_path = get_relative_path()

	-- Get visual selection line numbers
	local start_line, end_line = get_visual_selection()

	-- Format the location string
	local location_str = string.format("%s:%d-%d", relative_path, start_line, end_line)

	-- Get or create the frontier buffer
	local frontier_bufnr = get_frontier_buffer()

	-- Append the location string to the frontier buffer
	local lines = vim.api.nvim_buf_get_lines(frontier_bufnr, 0, -1, false)
	table.insert(lines, location_str)
	vim.api.nvim_buf_set_lines(frontier_bufnr, 0, -1, false, lines)

	-- Show a confirmation message
	vim.api.nvim_echo({ { string.format("Location saved: %s", location_str), "Normal" } }, true, {})
end

-- Setup function
function M.setup(opts)
	opts = opts or {}

	-- Set up the keymap (default to <leader>z if not specified)
	local keymap = opts.keymap or "<leader>z"
	vim.keymap.set(
		"v",
		keymap,
		M.save_selection_location,
		{ noremap = true, silent = true, desc = "Save selection location" }
	)
end

return M
