# cshelper.nvim

Set of useful commands for dotnet development.

## Installation:

```lua
{
  dir = "cantti/cshelper.nvim",
  opts = {},
},

```

## Usage

Convenient way is to map command picker:

```lua

vim.keymap.set({ "n", "v" }, "<leader>#", function() require("cshelper").commands() end)

```

Individual commands also available:


```lua

-- Fix namespace
require("cshelper").fix_ns({ 
  mode = "buffer",
  update_usings = true,
})

-- Put new class with correct namespace
require("cshelper").new_class({ 
  blockns = false,
})

-- Put new api controller with correct namespace
require("cshelper").new_api_controller({ 
  blockns = false,
})

-- Secrets list
require("cshelper").secrets_list()

-- Secrets edit
require("cshelper").secrets_edit()

```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
