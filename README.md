# dotnet-helper.nvim

dotnet-helper.nvim provides a collection of lightweight commands and utilities for .NET development in Neovim.
It’s designed to complement the standard LSP workflow — adding only the essential features missing from a typical Neovim + LSP configuration.

## Installation:

Using lazy:

```lua
{
  "cantti/dotnet-helper.nvim",
  -- default config
  opts = {
    -- create autocommands to insert c# class when enterin an empty C# file
    autocommands = {
      enabled = true,
      -- use block {} namespace for new files
      use_block_ns = false,
    },

    -- create :Dotnet ... user commands
    -- if not enabled lua api can be used
    usercommands = {
      enabled = true,
      -- use block {} namespace for templates
      use_block_ns = false,
    },
  },
},

```

## New C# file

The plugin can insert C# class when entering an empty C# file.

## Commands

This plugin offers a collection of helper functions implemented with Neovim’s Lua API.
Many of them are also accessible via user commands under the `:Dotnet` namespace.

### Templates (snippets)

```lua
-- choose template from picker
require("dotnet-helper").templates()

-- individual templates
require("dotnet-helper").templates_class()
require("dotnet-helper").templates_api_controller()
require("dotnet-helper").templates_method()
```

or

```
:Dotnet templates
```

### Fix namespace for buffer

```lua
require("dotnet-helper").fix_ns_buf()
```

or

```
:Dotnet ns
```

### Fix namespace for directory

```lua
require("dotnet-helper").fix_ns_dir()
```

or

```
:Dotnet ns --dir
```

### Edit Secrets

```lua
require("dotnet-helper").secrets_edit()
```

or

```
:Dotnet secrets
```

### List Secrets

```lua
require("dotnet-helper").secrets_list()
```

```
:Dotnet secrets --list
```

### Search and install nuget package

```lua
require("dotnet-helper").nuget_search()
```

```
:Dotnet nuget
```

### EF Core migrations actions

Supported actions: add, remove list.

```lua
require("dotnet-helper").migrations()
```

```
:Dotnet migrations
```

## Plans

- Add `dotnet new` support for common projects
- Add basic `dotnet sln` support

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
