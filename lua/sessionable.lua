local Lib = require("sessionable-library")
local themes = require('telescope.themes')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local Sessionable = {
  conf = {
    auto_save_enabled = true,
    log_level = "info",
    session_dir = vim.fn.stdpath("config") .. "/sessions/",
    scope_opts = {
      theme_conf = { winblend = 10, border = true },
      previewer = false
    }
  },
  session_name = "",
  session_file_path = ""
}

function Sessionable.setup(config)
  Sessionable.conf = Lib.Config.normalize(config, Sessionable.conf)
  Lib.session_dir = Sessionable.get_session_dir()
  Lib.setup {
    log_level = Sessionable.conf.log_level,
  }
end

local function run_hook_cmds(cmds, hook_name)
  if not Lib.is_empty_table(cmds) then
    for _, cmd in ipairs(cmds) do
      Lib.logger.debug(string.format("Running %s command: %s", hook_name, cmd))
      local success, result

      if type(cmd) == "function" then
        success, result = pcall(cmd)
      else
        success, result = pcall(vim.cmd, cmd)
      end

      if not success then
        Lib.logger.error(string.format("Error running %s. error: %s", cmd, result))
      end
    end
  end
end

local function message_after_saving(path, auto)
  if auto then
    Lib.logger.debug("Session saved at " .. path)
  else
    Lib.logger.info("Session saved at " .. path)
  end
end

function Sessionable.get_session_dir()
  if Sessionable.validated then
    return Sessionable.conf.session_dir
  end

  Lib.init_dir(Sessionable.conf.session_dir)
  Sessionable.conf.session_dir = Lib.validate_session_dir(Sessionable.conf.session_dir)
  Sessionable.validated = true
  return Sessionable.conf.session_dir
end

function Sessionable.get_cmds(type)
  return Sessionable.conf[type .. "_cmds"]
end

function Sessionable.AutoSaveSession()
  if Sessionable.conf.auto_save_enabled and not Lib.is_empty(Sessionable.session_name) then
    Sessionable.SaveSession(Sessionable.session_name, true)
  end
end

-- Saves the session, overriding if previously existing.
-- TODO: if user passes in :SaveSession newDir/sessionName, validate or create newDir
function Sessionable.SaveSession(session_name, auto)
  if Lib.is_empty(session_name) then
    session_name = Sessionable.session_name
  end

  if Lib.is_empty(session_name) then
      Lib.logger.error("No session name provided")
      return
  end

  local pre_cmds = Sessionable.get_cmds("pre_save")
  run_hook_cmds(pre_cmds, "pre-save")

  vim.cmd("mks! " .. Sessionable.get_session_dir() .. session_name)

  if session_name ~= Sessionable.session_name then
    Sessionable.session_name = session_name
  end

  Sessionable.session_file_path = string.format("%s%s", Sessionable.get_session_dir(), session_name)
  message_after_saving(Sessionable.session_file_path, auto)
  local post_cmds = Sessionable.get_cmds("post_save")
  run_hook_cmds(post_cmds, "post-save")
end

function Sessionable.RestoreSession(session_name)
  local restore = function()
    local pre_cmds = Sessionable.get_cmds("pre_restore")
    run_hook_cmds(pre_cmds, "pre-restore")

    local cmd = "source " .. Sessionable.session_file_path
    local success, result = pcall(vim.cmd, cmd)

    if not success then
      Lib.logger.error([[
        Error restoring session! The session might be corrupted.
        Disabling auto save. Please check for errors in your config. Error: 
      ]] .. result)
      Sessionable.conf.auto_save_enabled = false
      return
    end

    Lib.logger.info("Session restored from " .. Sessionable.session_file_path)
    Lib.conf.last_loaded_session = Sessionable.session_file_path 

    local post_cmds = Sessionable.get_cmds("post_restore")
    run_hook_cmds(post_cmds, "post-restore")
  end
  Sessionable.session_file_path = string.format("%s%s", Sessionable.get_session_dir(), session_name)

  if Lib.is_readable(Sessionable.session_file_path) then
    Lib.logger.debug("isReadable, calling restore")
    restore()
    Sessionable.session_name = session_name
  else
    Lib.logger.debug("File not readable, not restoring session")
  end
end

function Sessionable.DisableAutoSave()
  Lib.logger.debug "Auto Save disabled"
  Sessionable.conf.auto_save_enabled = false
end

function Sessionable.CompleteSessions()
  local session_files = vim.fn.glob(Sessionable.get_session_dir() .. "/*", true, true)
  local session_names = {}
  for _, sf in ipairs(session_files) do
    local name = Lib.unescape_dir(vim.fn.fnamemodify(sf, ":t:r"))
    table.insert(session_names, name)
  end
  return table.concat(session_names, "\n")
end

function Sessionable.DeleteSession(session_name)
  local pre_cmds = Sessionable.get_cmds("pre_delete")
  run_hook_cmds(pre_cmds, "pre-delete")

  -- make sure to disable autosave if we're deleting the active session
  if Sessionable.conf.auto_save_enabled and Lib.is_empty(session_name) then
    Sessionable.DisableAutoSave()
  end
  -- if a session name is passed in, use it, otherwise use the surrent session
  session_name = session_name or Sessionable.session_name
  Sessionable.session_file_path = string.format("%s%s", Sessionable.get_session_dir(), session_name)
  local cmd = "silent! !rm " .. Sessionable.session_file_path
  local success, result = pcall(vim.cmd, cmd)
  if success then
    Lib.logger.info("Deleted session " .. Sessionable.session_file_path)
    local post_cmds = Sessionable.get_cmds("post_delete")
    run_hook_cmds(post_cmds, "post-delete")
  else
    Lib.logger.error("Error deleting session " .. Sessionable.session_file_path)
  end
end

-- TODO: clean this up, it's a mess
function Sessionable.CreateGitSession()
  local is_git_dir = vim.fn.system("[ -d .git ] && echo .git || git rev-parse --git-dir > /dev/null 2>&1")

  if not Lib.is_empty(is_git_dir) then
    local branch = vim.fn.system("git branch --show-current"):gsub("/", "-")
    local git_dir = vim.fn.system("basename $(git rev-parse --show-toplevel)")
    local project_dir = vim.fn.system("basename " .. git_dir)

    project_dir = string.gsub(project_dir, "^%s*(.-)%s*$", "%1") .. "/"
    local session_dir = Sessionable.get_session_dir() .. project_dir

    Lib.init_dir(session_dir)
    Sessionable.SaveSession(project_dir .. branch)
  else
    Lib.logger.error("not in a git repo")
  end
end

function Sessionable.source_session(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  Sessionable.AutoSaveSession()
  vim.cmd("%bd!")
  Sessionable.RestoreSession(selection.path)
end

-- TODO: make this refresh the picker and not close it instead
function Sessionable.delete_session(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  Sessionable.DeleteSession(selection.path)
end

function Sessionable.SearchSession()
  -- local theme_opts = themes.get_dropdown(Sessionable.conf.scope_opts.theme_conf)

  local opts = {
    prompt_title = 'Sessions',
    entry_maker = Lib.make_entry(),
    cwd = Sessionable.get_session_dir(),
    -- TOOD: support custom mappings?
    attach_mappings = function(_, map)
      actions.select_default:replace(Sessionable.source_session)
      map("i", "<c-d>", Sessionable.delete_session)
      return true
    end,
  }
  -- local find_files_conf = vim.tbl_deep_extend("force", opts, theme_opts, or {})
  require("telescope.builtin").find_files(opts)
end

return Sessionable
