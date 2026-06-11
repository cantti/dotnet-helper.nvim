# dotnet-helper.nvim

dotnet-helper.nvim is a small helper plugin for .NET work in Neovim.
It gives you commands for user-secrets, NuGet search, and EF migrations, without changing your usual LSP workflow.

## Installation

Options:

```lua
local opts = {
  autocommands = {
    enabled = true,
    use_block_ns = false,
  },
  usercommands = {
    enabled = true,
    use_block_ns = false,
  },
}
```

Using lazy:

```lua
{
  "cantti/dotnet-helper.nvim",
  opts = opts,
},

```

Using vim.pack:

```lua
vim.pack.add({ "https://github.com/cantti/dotnet-helper.nvim" })

require("dotnet-helper").setup(opts)
```

## Auto template for new C# files

When `autocommands.enabled = true`, the plugin automatically inserts a C# class or interface when you open an empty `.cs` file.

## User commands

When `usercommands.enabled = true`, these commands are available:

```sh
# EF Core migrations actions (add/remove/list)
:DotnetMigrations

# open user-secrets actions
:DotnetSecrets

# search and install NuGet packages
:DotnetNuget
```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
