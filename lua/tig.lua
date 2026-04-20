local function pwd()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)") or './'
end

local function pwd_parent()
  return pwd():match("(.+/).*/")
end

local M = {}

M.state = {
  is_open = false,
}

-- Default options
M.config = {
  -- Command Options
  command = {
    -- Enable :Tigui command
    -- @type: bool
    enable = true,
  },
  -- Path to binary
  -- @type: string
  binary = "tig",
  -- Argumens to tig
  -- @type: table of string
  args = {},
  -- Environments Variables to tig
  -- @type: table of string
  envs = {},
  -- WIndow Options
  window = {
    options = {
      -- Width window in %
      -- @type: number
      width = 90,
      -- Height window in %
      -- @type: number
      height = 80,
      -- Border Style
      -- Enum: "none", "single", "rounded", "solid" or "shadow"
      -- @type: string
      border = "rounded",
    },
  },
  -- editor options
  editor = {
    -- editor path
    -- @type: string
    path = pwd_parent() .. 'script/callback_script.sh',
    -- Script to call editor
    -- @type function
    script = function()
      local tmpfile = '/tmp/tig_callback'
      local file = io.open(tmpfile, 'r')
      if file == nil then
        vim.cmd("redr")
      else
        local content = file:read('a')
        io.close(file)
        os.remove(tmpfile)
        vim.cmd(content)
      end
    end,
  },
}

M.setup = function(overrides)
  M.config = vim.tbl_deep_extend("force", M.config, overrides or {})

  if M.config.command.enable then
    vim.api.nvim_create_user_command('Tigui', require('tig').open, {})
  end
end

M.open = function()
  if M.state.is_open then return end

  -- tig
  assert(vim.fn.executable(M.config.binary) == 1, M.config.binary .. " not a executable")
  local cmd = M.config.binary
  local envs = vim.tbl_deep_extend('force', M.config.envs, { GIT_EDITOR = M.config.editor.path })
  local args = M.config.args

  -- floating window options
  local width = vim.api.nvim_get_option_value("columns", {})
  local height = vim.api.nvim_get_option_value("lines", {})
  local win_height = math.ceil(height * (M.config.window.options.height / 100))
  local win_width = math.ceil(width * (M.config.window.options.width / 100))
  local row = math.ceil((height - win_height) / 2)
  local col = math.ceil((width - win_width) / 2)

  local window_options = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = M.config.window.options.border,
    noautocmd = true,
  }

  -- create window
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(bufnr, true, window_options)

  -- execute
  local on_exit_func = function(_, _)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    M.state.is_open = false
    M.config.editor.script()
  end

  vim.fn.jobstart(cmd, { term = true, env = envs, arg = args, on_exit = on_exit_func })
  vim.cmd.startinsert()
  M.state.is_open = true
end

return M
