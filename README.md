# Fzf-dotnet.nvim

Set of usefull commands for dotnet development. Only unix filesystems supported.

<img width="968" alt="Screenshot 2025-01-18 at 9 41 39 PM" src="https://github.com/user-attachments/assets/b359edcb-1f22-4e83-81fc-ba0b64beffc0" />

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
