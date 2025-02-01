# cshelper.nvim

Set of useful commands for dotnet development.

<img width="655" alt="image" src="https://github.com/user-attachments/assets/16478ee0-cee0-490f-8268-37254a75192e" />

Uses https://github.com/ibhagwan/fzf-lua

## Installation:

```lua
{
  dir = "cantti/cshelper.nvim",
  opts = {},
  dependencies = { "ibhagwan/fzf-lua" },
},

```

## Usage


```sh
# show all commands
:Csh

# create new c# class
:Csh newclass

# build 
:Csh build

# build project or solution
:Csh buildproject

# edit secrets.json
:Csh secretsedit

# show secrets
:Csh secretslist
```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
