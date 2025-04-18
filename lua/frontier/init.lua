local M = {}
local config = require("frontier.config")

function M.setup(user_opts)
  local opts = config.setup(user_opts) or {}

  local key_main = opts.keys.main or "<leader>z"
  local key_add_current_file = opts.keys.add_current_file or "<leader>\\"
  vim.keymap.set(
    "v",
    key_main,
    M.save_selection_location,
    { noremap = true, silent = true, desc = "Save selection location" }
  )

  -- Set up the normal mode keymap (default to <leader>z)
  vim.keymap.set(
    "n",
    key_main,
    M.toggle_frontier_window,
    { noremap = true, silent = true, desc = "Toggle frontier window" }
  )

  -- Set up keymap to add current file to frontier
  vim.keymap.set(
    "n",
    key_add_current_file,
    M.add_current_file,
    { noremap = true, silent = true, desc = "Add Current File to Frontier" }
  )
end

-- Store the window ID globally to track if it's open
M.frontier_win_id = nil

-- Function to get the relative path of the current buffer
local function get_relative_path()
  local absolute_path = vim.fn.expand("%:p")
  local current_dir = vim.fn.getcwd()
  local relative_path = vim.fn.fnamemodify(absolute_path, ":." .. current_dir .. ":~:.")
  return relative_path
end

local function get_visual_selection()
  local start_pos = vim.fn.getpos("v") -- start of visual selction
  local end_pos = vim.fn.getpos(".") -- current cursor position

  if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
    start_pos, end_pos = end_pos, start_pos
  end

  return start_pos[2], end_pos[2]
end

-- Function to get frontier file path for current working directory
local function get_frontier_file()
  local cwd = vim.fn.getcwd()
  local cwd_hash = vim.fn.sha256(cwd)
  local cache_dir = vim.fn.stdpath("data") .. "/frontier"

  -- Create cache directory if it doesn't exist
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, "p")
  end

  return cache_dir .. "/" .. cwd_hash
end

-- Function to load frontier content from file into a buffer
local function load_frontier_content(bufnr)
  local filepath = get_frontier_file()
  if vim.fn.filereadable(filepath) == 1 then
    local lines = vim.fn.readfile(filepath)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end
end

-- Function to save frontier content to file
local function save_frontier_content(bufnr)
  local filepath = get_frontier_file()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  vim.fn.writefile(lines, filepath)
end

-- Function to create or get the frontier buffer
local function get_frontier_buffer()
  local buffer_name = ".frontier:" .. vim.fn.getcwd()
  local frontier_bufnr = vim.fn.bufnr(buffer_name)

  if frontier_bufnr == -1 then
    -- Create a new buffer with path-specific name
    frontier_bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(frontier_bufnr, buffer_name)

    -- Set buffer options
    -- Scratch buffer can still be accessed by other buffer!
    vim.bo[frontier_bufnr].buftype = "nofile" -- Scratch buffer
    vim.bo[frontier_bufnr].bufhidden = "hide"
    vim.bo[frontier_bufnr].buflisted = false
    vim.bo[frontier_bufnr].swapfile = false
    vim.bo[frontier_bufnr].modifiable = true

    -- Load existing content if any
    load_frontier_content(frontier_bufnr)

    -- Set up autocmd to save content when buffer is written
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = frontier_bufnr,
      callback = function()
        save_frontier_content(frontier_bufnr)
        vim.bo[frontier_bufnr].modified = false
        -- vim.notify("Frontier content saved", vim.log.levels.INFO)
      end,
    })
  end

  return frontier_bufnr
end

-- Function to go to selected location
function M.go_to_selected()
  -- Get the current line
  local line = vim.api.nvim_get_current_line()

  -- Parse the line
  local path, line_range = string.match(line, "([^:]+):?(.*)$")
  if not path then
    return
  end

  -- Get start line number if it exists
  local start_line = 1
  if line_range ~= "" then
    ---@diagnostic disable-next-line: cast-local-type
    start_line = tonumber(string.match(line_range, "(%d+)"))
  end

  -- Close the floating window
  if M.frontier_win_id and vim.api.nvim_win_is_valid(M.frontier_win_id) then
    vim.api.nvim_win_close(M.frontier_win_id, true)
    M.frontier_win_id = nil
  end

  -- Open the file
  vim.cmd("edit " .. path)

  -- Go to the line if we have one
  if start_line then
    vim.api.nvim_win_set_cursor(0, { start_line, 0 })
    -- Center the view
    vim.cmd("normal! zz")
  end
end

-- Function to create a floating window
local function open_floating_window(bufnr)
  -- Get editor dimensions
  local width = vim.opt.columns:get()
  local height = vim.opt.lines:get()

  -- Calculate floating window size (30% of editor size)
  local win_height = math.ceil(height * 0.3)
  local win_width = math.ceil(width * 0.3)

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
    title = "Frontier",
    title_pos = "center",
  }

  -- Create the floating window
  local win_id = vim.api.nvim_open_win(bufnr, true, opts)

  -- Set window-local options
  vim.wo[win_id].wrap = false
  vim.wo[win_id].number = true

  -- Add autocommand to clear window ID when buffer is closed
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = bufnr,
    callback = function()
      if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        M.frontier_win_id = nil
      end
    end,
  })

  -- Add keymaps for the floating window
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
      M.frontier_win_id = nil
    end
  end, { buffer = bufnr, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
      M.frontier_win_id = nil
    end
  end, { buffer = bufnr, silent = true })

  -- Add Enter keymap to go to selected location
  vim.keymap.set("n", "<CR>", M.go_to_selected, { buffer = bufnr, silent = true })

  return win_id
end

-- Function to save selection location (without opening window)
function M.save_selection_location()
  -- Preserve the visual selection mode
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "" then
    return
  end

  -- Get the relative path
  local relative_path = get_relative_path()

  -- Get visual selection line numbers
  local start_line, end_line = get_visual_selection()

  -- Format the location string
  local location_str = string.format("%s:%d-%d", relative_path, start_line, end_line)

  -- Get or create the frontier buffer
  local frontier_bufnr = get_frontier_buffer()

  -- Get existing lines and append the new location string
  local lines = vim.api.nvim_buf_get_lines(frontier_bufnr, 0, -1, false)
  if #lines == 1 and lines[1] == "" then
    -- If buffer is empty (just has one blank line), replace it
    vim.api.nvim_buf_set_lines(frontier_bufnr, 0, -1, false, { location_str })
  else
    -- Otherwise append to existing content
    vim.api.nvim_buf_set_lines(frontier_bufnr, -1, -1, false, { location_str })
  end

  -- Mark buffer as modified
  vim.bo[frontier_bufnr].modified = true

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  -- Show a confirmation message
  vim.api.nvim_echo({ { string.format("Location saved: %s", location_str), "Normal" } }, true, {})
end

-- Function to add current file to frontier
function M.add_current_file()
  -- Get the relative path
  local relative_path = get_relative_path()

  -- Get or create the frontier buffer
  local frontier_bufnr = get_frontier_buffer()

  -- Get existing lines and append the new location string
  local lines = vim.api.nvim_buf_get_lines(frontier_bufnr, 0, -1, false)
  if #lines == 1 and lines[1] == "" then
    -- If buffer is empty (just has one blank line), replace it
    vim.api.nvim_buf_set_lines(frontier_bufnr, 0, -1, false, { relative_path })
  else
    -- Otherwise append to existing content
    vim.api.nvim_buf_set_lines(frontier_bufnr, -1, -1, false, { relative_path })
  end

  -- Mark buffer as modified
  vim.bo[frontier_bufnr].modified = true

  -- Show a confirmation message
  vim.api.nvim_echo({ { string.format("File added to Frontier: %s", relative_path), "Normal" } }, true, {})
end

-- Function to toggle the frontier window
function M.toggle_frontier_window()
  -- If window exists and is valid, close it
  if M.frontier_win_id and vim.api.nvim_win_is_valid(M.frontier_win_id) then
    local frontier_bufnr = vim.api.nvim_win_get_buf(M.frontier_win_id)
    save_frontier_content(frontier_bufnr)
    vim.api.nvim_win_close(M.frontier_win_id, true)
    M.frontier_win_id = nil
    return
  end

  -- Otherwise, open the window
  local frontier_bufnr = get_frontier_buffer()
  M.frontier_win_id = open_floating_window(frontier_bufnr)
end

-- M.toggle_frontier_window()

return M
