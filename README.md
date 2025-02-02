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


```sh
# show all commands
:Csh

# create new c# class
:Csh class
:Csh class blockns # block namespace

# create new c# api controller
:Csh apicontroller
:Csh apicontroller blockns # block namespace

# run 
:Csh run

# build 
:Csh build

# clean 
:Csh clean

# fix namespace (asks for directory where to fix) 
:Csh fixns

# list secrets in secrets.json
:Csh secretlist

# edit secrets.json
:Csh secretsedit
```

## Alternatives and similar plugins

- https://github.com/GustavEikaas/easy-dotnet.nvim
- https://github.com/MoaidHathot/dotnet.nvim
- https://github.com/DestopLine/boilersharp.nvim
