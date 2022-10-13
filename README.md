# Sessionable

<!--toc:start-->
- [Installion](#installation)
- [Sessionable](#sessionable)
- [Config](#config)
- [Commands](#commands)
<!--toc:end-->

## Installation

This plugin requires [Telescope](https://www.github.com/nvim-telescope/telescope.nvim)

```lua
use { 'blaineventurine/sessionable',
      requires = { 'nvim-telescope/telescope.nvim' },
    }
```

## Config

Defaults:

```lua
{
  auto_save_enabled = true,
  enable_last_session = false,
  log_level = "info",
  session_dir = vim.fn.stdpath("config") .. "/sessions/",
  {hook_name}_cmds = {"{hook_command1}", "{hook_command2}"}
}
```

To modify defaults, pass them into

```lua
require("sessionable").setup({
  log_level = "debug"
})
```

To add the current session name (if any) to [Feline](https://github.com/feline-nvim/feline.nvim)

```lua
components.active[3][11] = {
  provider = function()
    return require('sessionable').session_name
  end,
  hl = {
    fg = 'green',
    bg = 'bg',
  },
  right_sep = ' ',
  left_sep = ' '
}
```

## Hooks

Command hooks exist in the format: {hook_name}

{pre_save}: executes before a session is saved
{post_save}: executes after a session is saved
{pre_restore}: executs before a session is restored
{post_restore}: executs after a session is restored
{pre_delete}: executs before a session is deleted
{post_delete}: executs after a session is deleted

```lua
require('sessionable').setup {
    {hook_name}_cmds = {"{hook_command1}", "{hook_command2}"}
}
```

Hooks can also be lua functions

For example to update the directory of the session in nvim-tree:

```lua
local function restore_nvim_tree()
    local nvim_tree = require('nvim-tree')
    nvim_tree.change_dir(vim.fn.getcwd())
    nvim_tree.refresh()
end

require('sessionable').setup {
    {hook_name}_cmds = {"{vim_cmd_1}", restore_nvim_tree, "{vim_cmd_2}"}
}
```

## Commands

```lua
-- saves the current session in the session_dir.
:SaveSesson
-- creates a session in the session_dir and switches to it being the active session.
:SaveSession mySessionName
-- restores a previously saved session by name.
:RestoreSession
-- deletes currently active session
:DeleteSession
-- deletes a session by name
:DeleteSession mySessionName
-- creates a new session using the repo name as a subfolder 
-- and a branch name as the session name
:CreateGitSession
-- turns off the autosave on exit functionality
-- will be overridden by the value passed into the config on next startup
:DisableAutoSave
-- uses Telescope to browse existing sessions
:SearchSessions
```
