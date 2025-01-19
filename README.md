# Fzf-dotnet.nvim

Set of useful commands for dotnet development.

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

# build 
:Fzfdotnet build

# build project or solution
:Fzfdotnet buildproject

# edit secrets.json
:Fzfdotnet secretsedit

# show secrets
:Fzfdotnet secretslist
```

## Alternatives

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
