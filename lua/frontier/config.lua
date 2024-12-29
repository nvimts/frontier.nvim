local M = {}

local defaults = {
  keymap = "<leader>z",
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  return opts
end

return M
