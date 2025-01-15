# Fzf-dotnet.nvim

Work in progress!

Set of usefull commands for dotnet development. Only unix filesystems supported.

Uses https://github.com/ibhagwan/fzf-lua

Installation:

```lua
{
  dir = "cantti/fzf-dotnet.nvim",
  opts = {},
  dependencies = { "ibhagwan/fzf-lua" },
},

```

Usage:


```sh
# show all commands
:Fzfdotnet

# create new c# class
:Fzfdotnet newclass

# build solution (finds solution automatically)
:Fzfdotnet buildsln

# build project or solution
:Fzfdotnet build
```
