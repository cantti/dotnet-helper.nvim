# Fzf-dotnet.nvim

Set of usefull commands for dotnet development. Only unix filesystems supported.

<img width="655" alt="image" src="https://github.com/user-attachments/assets/16478ee0-cee0-490f-8268-37254a75192e" />

Uses https://github.com/ibhagwan/fzf-lua

## Installation:

```lua
{
  dir = "cantti/fzf-dotnet.nvim",
  opts = {},
  dependencies = { "ibhagwan/fzf-lua" },
},

```

## Usage


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

## Alternatives

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
