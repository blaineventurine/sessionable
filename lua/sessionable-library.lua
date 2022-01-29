local Config = {}
local Lib = {
  logger = {},
  conf = {
    log_level = false,
    last_loaded_session = nil,
  },
  Config = Config,
  _VIM_FALSE = 0,
  _VIM_TRUE = 1,
  session_dir = nil,
}

function Lib.setup(config)
  Lib.conf = Config.normalize(config)
end

function Config.normalize(config, existing)
  local conf = existing or {}
  if Lib.is_empty_table(config) then
    return conf
  end

  for k, v in pairs(config) do
    conf[k] = v
  end

  return conf
end

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

function Lib.get_file_name(url)
  return url:match "^.+/(.+)$"
end

function Lib.get_file_extension(url)
  return url:match "^.+(%..+)$"
end

function Lib.is_empty_table(t)
  if t == nil then
    return true
  end
  return next(t) == nil
end

function Lib.is_empty(s)
  return s == nil or s == ""
end

function Lib.ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

function Lib.append_slash(str)
  if not Lib.is_empty(str) then
    if not Lib.ends_with(str, "/") then
      str = str .. "/"
    end
  end
  return str
end

function Lib.validate_session_dir(session_dir)

  if not Lib.ends_with(session_dir, "/") then
    session_dir = session_dir .. "/"
  end

  if Lib.is_empty(session_dir) or vim.fn.expand(session_dir) == vim.fn.expand(Lib.session_dir) then
    return Lib.session_dir
  end

  if vim.fn.isdirectory(vim.fn.expand(session_dir)) == Lib._VIM_FALSE then
    vim.cmd(
        "Path does not exist or is not a directory. "
        .. string.format("Defaulting to %s.", Lib.session_dir)
    )
    return Lib.session_dir
  else
    Lib.logger.debug("Using session dir: " .. session_dir)
    return session_dir
  end
end

function Lib.init_dir(dir)
  if vim.fn.isdirectory(vim.fn.expand(dir)) == Lib._VIM_FALSE then
    vim.fn.mkdir(dir, "p")
  end
end

function Lib.init_file(file_path)
  if not Lib.is_readable(file_path) then
    vim.cmd("!touch " .. file_path)
  end
end

function Lib.is_readable(file_path)
  local readable = vim.fn.filereadable(vim.fn.expand(file_path)) == Lib._VIM_TRUE
  Lib.logger.debug("==== is_readable", readable)
  return readable
end

function Lib.make_entry()
  return function(line)
    return {
      ordinal = line,
      value = line,
      filename = line,
      cwd = Lib.session_dir,
      display = function(_)
        return line
      end,
      path = line
    }
  end
end

function Lib.logger.debug(...)
  if Lib.conf.log_level == "debug" then
    print('DEBUG: ', ...)
  end
end

function Lib.logger.info(...)
  local valid_values = { "info", "debug" }
  if has_value(valid_values, Lib.conf.log_level) then
    print('INFO: ', ...)
  end
end

function Lib.logger.error(...)
  error('ERROR: ' .. ..., 2)
end

return Lib
