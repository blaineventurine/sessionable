-- TODO: add telescope plugin for sessions
-- 
local Lib = require "sessionable-library"

local Sessionable = {
  conf = {
    auto_save_enabled = true,
    enable_last_session = false,
    log_level = "info",
    session_dir = vim.fn.stdpath("config") .. "/sessions/",
  },
  session_name = "",
  session_file_path = ""
}

function Sessionable.setup(config)
  Sessionable.conf = Lib.Config.normalize(config, Sessionable.conf)
  Lib.session_dir = Sessionable.conf.session_dir
  Lib.setup {
    log_level = Sessionable.conf.log_level,
  }
end

do
  function Sessionable.get_latest_session()
    local dir = vim.fn.expand(Sessionable.conf.session_dir)
    local latest_session = { session = nil, last_edited = 0 }

    for _, filename in ipairs(vim.fn.readdir(dir)) do
      local session = Sessionable.conf.session_dir .. filename
      local last_edited = vim.fn.getftime(session)

      if last_edited > latest_session.last_edited then
        latest_session.session = session
        latest_session.last_edited = last_edited
      end
    end
  end
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

  local session_dir = vim.g["session_dir"] or Sessionable.conf.session_dir
  Lib.init_dir(session_dir)
  Sessionable.conf.session_dir = Lib.validate_session_dir(session_dir)
  Sessionable.validated = true
  return session_dir
end

function Sessionable.get_cmds(type)
  return Sessionable.conf[type .. "_cmds"]
end

function Sessionable.AutoSaveSession()
  print('calling auto save')
  print(Sessionable.conf.auto_save_enabled)
  if Sessionable.conf.auto_save_enabled then
    print('auto save enabled')
    print('name: ', Sessionable.session_name)
    Sessionable.SaveSession(Sessionable.session_name, true)
  end
end

-- Saves the session, overriding if previously existing.
function Sessionable.SaveSession(session_name, auto)
  if session_name == nil or session_name == "" then
    session_name = Sessionable.session_name
  end
  
  local pre_cmds = Sessionable.get_cmds("pre_save")
  run_hook_cmds(pre_cmds, "pre-save")
  vim.cmd("mks! " .. Sessionable.conf.session_dir  .. session_name)

  if session_name ~= Sessionable.session_name then
    Sessionable.session_name = session_name
  end

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
  print('Auto save enabled? ', Sessionable.conf.auto_save_enabled)
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
  if Sessionable.conf.auto_save_enabled and session_name == nil then
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
    Lib.logger.error("Error deleting session " .. Sessionable.session_file_pathj)
  end
end


function Sessionable.CreateGitSession()
    -- TODO: something like git rev-parse --abbrev-ref HEAD to get current branch name?

end
return Sessionable
