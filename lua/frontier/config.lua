local M = {}

local defaults = {
  keys = {  main = "<leader>z", add_current_file = "<leader>\\",
  }
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  return opts
end

return M
