# cshelper.nvim

Set of useful commands for dotnet development.

## Installation:

```lua
{
  "cantti/cshelper.nvim",
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

### Templates (snippets)

```lua
-- choose template from picker
require("cshelper").templates()

-- individual templates
require("cshelper").templates_class()
require("cshelper").templates_api_controller()
require("cshelper").templates_method()
```

### Fix namespace for buffer

```lua
require("cshelper").fix_ns_buf()
```

### Fix namespace for directory

```lua
require("cshelper").fix_ns_dir()
```

### List Secrets

```lua
require("cshelper").secrets_list()
```

### Edit Secrets

```lua
require("cshelper").secrets_edit()
```

### Search and install nuget package

```lua
require("cshelper").nuget_search()
```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
