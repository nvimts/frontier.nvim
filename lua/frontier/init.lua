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
		frontier_bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(frontier_bufnr, "frontier")

		-- Set buffer options using vim.bo
		vim.bo[frontier_bufnr].buftype = "nofile"
		vim.bo[frontier_bufnr].bufhidden = "hide"
		vim.bo[frontier_bufnr].swapfile = false
		vim.bo[frontier_bufnr].modifiable = true
	end
	return frontier_bufnr
end

-- Function to create a floating window
local function open_floating_window(bufnr)
	-- Get editor dimensions
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- Calculate floating window size (50% of editor size)
	local win_height = math.ceil(height * 0.5)
	local win_width = math.ceil(width * 0.5)

	-- Calculate starting position (centered)
	local row = math.ceil((height - win_height) / 2)
	local col = math.ceil((width - win_width) / 2)

	-- Set up window options
	local opts = {
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		border = "rounded",
		style = "minimal",
	}

	-- Create the floating window
	local win_id = vim.api.nvim_open_win(bufnr, true, opts)

	-- Set window-local options
	vim.wo[win_id].wrap = false
	vim.wo[win_id].number = true

	-- Add autocommand to close window with q or <Esc>
	vim.api.nvim_create_autocmd("BufWinLeave", {
		buffer = bufnr,
		callback = function()
			if vim.api.nvim_win_is_valid(win_id) then
				vim.api.nvim_win_close(win_id, true)
			end
		end,
	})

	-- Add keymaps for the floating window
	vim.keymap.set("n", "q", ":q<CR>", { buffer = bufnr, silent = true })
	vim.keymap.set("n", "<Esc>", ":q<CR>", { buffer = bufnr, silent = true })

	return win_id
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

	-- Make sure the buffer is modifiable
	vim.bo[frontier_bufnr].modifiable = true

	-- Append the location string to the frontier buffer
	local lines = vim.api.nvim_buf_get_lines(frontier_bufnr, 0, -1, false)
	table.insert(lines, location_str)
	vim.api.nvim_buf_set_lines(frontier_bufnr, 0, -1, false, lines)

	-- Show the buffer in a floating window
	open_floating_window(frontier_bufnr)

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
