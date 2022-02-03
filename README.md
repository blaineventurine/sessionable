# Sessionable

## Config
```lua
  conf = {
    auto_save_enabled = true,
    enable_last_session = false,
    log_level = "info",
    session_dir = vim.fn.stdpath("config") .. "/sessions/",
  },
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

## Commands 

```lua
:SaveSesson -- saves the current session in the session_dir.
:SaveSession mySessionName -- creates a session in the session_dir and switches to it being the active session.
:RestoreSession -- restores a previously saved session by name.
:DeleteSession -- deletes currently active session 
:DeleteSession mySessionName -- deletes a session by name 
:CreateGitSession -- creates a new session using the repo name as a subfolder and a branch name as the session name
:DisableAutoSave -- turns off the autosave on exit functionality, will be overridden by the value passed into the config on next startup
```
