local M = {}

local defaults = {
  keymap = "<leader>z",
}

-- Internal function to setup the plugin
local function setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  return opts
end

-- Configuration function
function M.config()
  return function(user_opts)
    local opts = setup(user_opts)
    return opts
  end
end

return M
