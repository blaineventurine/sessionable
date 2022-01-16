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
