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
vim.keymap.set("n", "<leader>#", function() require("cshelper").commands() end)
```

Or map individual commands:

```lua
vim.keymap.set("n", "<leader>#", require("cshelper").secrets_list() end)
```

## Individual Commands

Below are examples of how to use the available commands in `cshelper`:

### Fix namespace for buffer

```lua
require("cshelper").fix_ns_buf()
```

### Fix namespace for directory

```lua
require("cshelper").fix_ns_dir()
```

### Create New Class

```lua
require("cshelper").new_class({ use_block_ns = false })
```

### Create New API Controller

```lua
require("cshelper").new_api_controller({ use_block_ns = false })
```

### List Secrets

```lua
require("cshelper").secrets_list()
```

### Edit Secrets

```lua
require("cshelper").secrets_edit()
```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
