# Frontier.nvim

Frontier.nvim is a better context manager for avaten.nvim.

It uses a floating window to manage code context for LLM. The user interface/experience is similar to Harpoon.

Use keymaps to add files and any selected code as context. Their locations is saved into the floating window. Frontier buffer is persistent and project path specific.

## Features

- Floating window interface for multiple selected files and code blocks
- Save and navigate to file selections
- Add current file to frontier floating window
- Toggle frontier window visibility
- Persistent selection locations
- Selection locations are project path specific

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'nvimts/frontier.nvim',
  config = function()
    require('frontier').setup()
  end
}

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'nvimts/frontier.nvim',
  config = function()
    require('frontier').setup()
  end
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'nvimts/frontier.nvim'
```

## Configuration

Setup with default options:

```lua
require('frontier').setup()
```

Custom configuration:

```lua
require('frontier').setup({
  -- your custom keymaps
  keys = {
    main = '<leader>z',
    add_current_file = '<leader>\\',
  }
})
```

## Usage

Use keymaps to add files, selected code and toggle the floating window.
The floating window is normal buffer you can add, edit and delete like normal Neovim buffer.
The changes are automatically saved.

keymap main is default to "\<leader\>z"
keymap add_current_file is default to "\<leader\>\\" (i.e. pressing \<leader\> then backslash)

In normal mode:
- "\<leader\>z":           Toggle the floating window
- "\<leader\>\\":          Add current file to floating window

In visual mode:
- "\<leader\>z":           Add selected code location to floating window

Inside the floating window, press Enter to go to the first line of selected code.

## Usage with "nvimts/avante.nvim"

Change your plugin config from "yetone/avante.nvim" to "nvimts/avante.nvim" (It is a fork).
Then avante.nvim will automatically use content specified by the frontier floating window as the code context for LLM. Enjoy!

## Requirements

- Neovim 0.5.0 or higher

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
