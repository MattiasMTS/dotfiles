local M = {}

local function cli()
  return vim.env.CMUX_BUNDLED_CLI_PATH or "cmux"
end

local AGENT_TITLE_PATTERNS = { "Claude Code", "Claude", "Codex", "Amp" }
local AGENT_SURFACE_CACHE_TTL_MS = 5000
local agent_surface_cache = {}

local function shorten(s, max)
  s = tostring(s or "")
  if #s <= max then
    return s
  end
  return s:sub(1, max - 3) .. "..."
end

local function now_ms()
  return math.floor((vim.uv or vim.loop).hrtime() / 1000000)
end

local function patterns_key(patterns)
  return table.concat(patterns or {}, "\n")
end

local function cache_key(patterns)
  return table.concat({
    vim.env.CMUX_WORKSPACE_ID or "",
    vim.env.CMUX_SURFACE_ID or "",
    patterns_key(patterns),
  }, "\t")
end

local function state_surface_key(value)
  return (tostring(value or ""):gsub("[^%w%-]", ""))
end

local function clean_tmpdir()
  return (vim.env.TMPDIR or "/tmp"):gsub("/+$", "")
end

local function read_first_line(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  return lines[1]
end

local function read_agent_states()
  local states = {}
  local labels = {}
  local files = vim.fn.glob(clean_tmpdir() .. "/cmux-agent-state-*/*.state", false, true)
  for _, file in ipairs(files) do
    local line = read_first_line(file)
    if line and line ~= "" then
      local fields = vim.split(line, "\t", { plain = true })
      local surface_key = fields[6]
      if surface_key and surface_key ~= "" then
        local state = {
          agent_key = fields[1],
          agent_title = fields[2],
          start_ts = tonumber(fields[3]),
          status = fields[4],
          detail = fields[5],
          surface_key = surface_key,
          tab_title = fields[7],
          status_color = fields[8],
          active = fields[9] == "1",
        }
        states[surface_key] = state
        table.insert(labels, (state.agent_title or state.agent_key or "agent") .. ":" .. surface_key)
      end
    end
  end
  return states, labels
end

local function tree_ttys_by_surface_ref()
  local ws = vim.env.CMUX_WORKSPACE_ID
  if not ws or ws == "" then
    return {}
  end

  local res = vim.system({ cli(), "tree", "--workspace", ws }, { text = true }):wait()
  if res.code ~= 0 then
    return {}
  end

  local ttys = {}
  for line in (res.stdout or ""):gmatch("[^\r\n]+") do
    local ref, tty = line:match("(surface:%d+).+tty=([^%s]+)")
    if ref and tty then
      ttys[ref] = tty
    end
  end
  return ttys
end

local function parse_tree_surface(line)
  local ref = line:match("(surface:%d+)")
  if not ref then
    return nil
  end
  return {
    ref = ref,
    title = line:match('%[terminal%]%s+"(.-)"') or line:match('%[browser%]%s+"(.-)"') or "cmux surface",
    type = line:match("%[(terminal)%]") or line:match("%[(browser)%]") or "surface",
    tty = line:match("tty=([^%s]+)"),
    is_current = line:find(" here", 1, true) ~= nil,
  }
end

local function list_tree_surfaces()
  local ws = vim.env.CMUX_WORKSPACE_ID
  if not ws or ws == "" then
    return nil, "CMUX_WORKSPACE_ID not set in env"
  end

  local res = vim.system({ cli(), "tree", "--workspace", ws }, { text = true }):wait()
  if res.code ~= 0 then
    local stderr_trimmed = ((res.stderr or ""):gsub("%s+$", ""))
    return nil, "cmux tree exited " .. tostring(res.code) .. ": " .. stderr_trimmed
  end

  local surfaces = {}
  for line in (res.stdout or ""):gmatch("[^\r\n]+") do
    local surface = parse_tree_surface(line)
    if surface then
      table.insert(surfaces, surface)
    end
  end
  if #surfaces == 0 then
    return nil, "cmux tree returned no surfaces"
  end
  return surfaces, nil
end

local function ps_commands_for_tty(tty, cache)
  if not tty or tty == "" then
    return {}
  end
  if cache[tty] then
    return cache[tty]
  end

  local res = vim.system({ "ps", "-t", tty, "-o", "command=" }, { text = true }):wait()
  if res.code ~= 0 then
    cache[tty] = {}
    return {}
  end

  local commands = {}
  for line in (res.stdout or ""):gmatch("[^\r\n]+") do
    local command = line:gsub("^%s+", "")
    if command ~= "" then
      table.insert(commands, command)
    end
  end
  cache[tty] = commands
  return commands
end

local function detect_agent_from_command(command)
  local lower = tostring(command or ""):lower()
  if lower:find("codex", 1, true) then
    return "Codex"
  end
  if lower:find("claude", 1, true) then
    return "Claude"
  end
  if lower:find("/amp", 1, true) or lower:find("sourcegraph/amp", 1, true) then
    return "Amp"
  end
  return nil
end

local function detect_agent_from_screen(screen)
  if type(screen) ~= "string" or screen == "" then
    return nil
  end
  if screen:find("OpenAI Codex", 1, true) then
    return "Codex"
  end
  if screen:find("gpt-", 1, true) and screen:find("Context", 1, true) and screen:find("tokens", 1, true) then
    return "Codex"
  end
  if screen:find("Claude Code", 1, true) then
    return "Claude"
  end
  if screen:find("sourcegraph/amp", 1, true) or screen:find("Amp", 1, true) then
    return "Amp"
  end
  return nil
end

local function read_surface_screens(surfaces)
  local jobs = {}
  for _, surface in ipairs(surfaces) do
    local ref = M.surface_ref(surface)
    if ref then
      table.insert(jobs, {
        surface = surface,
        job = vim.system({ cli(), "read-screen", "--surface", ref, "--scrollback", "--lines", "120" }, { text = true }),
      })
    end
  end

  local screens = {}
  for _, item in ipairs(jobs) do
    local res = item.job:wait()
    if res.code == 0 then
      screens[item.surface] = res.stdout or ""
    end
  end
  return screens
end

local function copy_surface(surface)
  return vim.tbl_extend("force", {}, surface)
end

local function apply_agent_metadata(surface, metadata)
  local out = copy_surface(surface)
  out.agent = metadata.agent or out.agent
  out.agent_key = metadata.agent_key or out.agent_key
  out.status = metadata.status or out.status
  out.detail = metadata.detail or out.detail
  out.tab_title = metadata.tab_title or out.tab_title
  out.active = metadata.active
  out.agent_state = metadata.agent_state
  out.detected_by = metadata.detected_by
  out.tty = metadata.tty or out.tty
  return out
end

---@param surface string|table
---@return string?
function M.surface_ref(surface)
  if type(surface) == "string" then
    return surface
  end
  if type(surface) ~= "table" then
    return nil
  end
  return surface.ref or surface.id
end

---@param surface table
---@return string
function M.surface_label(surface)
  local title = surface.tab_title or surface.title or surface.name or "cmux surface"
  local ref = M.surface_ref(surface) or "?"
  local agent = surface.agent or surface.type
  local status = surface.status
  if type(surface.detail) == "string" and surface.detail ~= "" then
    status = type(status) == "string" and status ~= "" and (status .. " - " .. surface.detail) or surface.detail
  end
  local bits = { shorten(title, 54), "[" .. shorten(ref, 18) .. "]" }
  if type(agent) == "string" and agent ~= "" then
    table.insert(bits, agent)
  end
  if type(surface.tty) == "string" and surface.tty ~= "" then
    table.insert(bits, surface.tty)
  end
  if type(status) == "string" and status ~= "" then
    table.insert(bits, status)
  end
  return table.concat(bits, "  ")
end

---@return table[]? surfaces, string? err
function M.list_surfaces()
  local ws = vim.env.CMUX_WORKSPACE_ID
  if not ws or ws == "" then
    return nil, "CMUX_WORKSPACE_ID not set in env"
  end
  local res = vim
    .system({ cli(), "rpc", "surface.list", vim.json.encode({ workspace_id = ws }) }, { text = true })
    :wait()
  if res.code ~= 0 then
    local stderr_trimmed = ((res.stderr or ""):gsub("%s+$", ""))
    return nil, "cmux rpc exited " .. tostring(res.code) .. ": " .. stderr_trimmed
  end
  local stdout = res.stdout or ""
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok or type(decoded) ~= "table" then
    return nil, "cmux rpc returned invalid JSON: " .. stdout:sub(1, 200)
  end
  if type(decoded.surfaces) ~= "table" then
    return nil, "cmux rpc response missing surfaces key"
  end
  return decoded.surfaces, nil
end

local function title_matches(title, patterns)
  if type(title) ~= "string" then
    return false
  end
  for _, pattern in ipairs(patterns) do
    if title:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

local function state_for_surface(states, surface)
  return states[state_surface_key(surface.id)] or states[state_surface_key(surface.ref)]
end

local function state_matches(state, patterns)
  if type(state) ~= "table" then
    return false
  end
  return title_matches(state.agent_title, patterns) or title_matches(state.agent_key, patterns)
end

local function agent_matches(agent, patterns)
  return title_matches(agent, patterns)
end

---@param opts? {patterns?: string[], cache?: boolean, screen_fallback?: boolean}
---@return table[]? surfaces, string? err
function M.list_agent_surfaces(opts)
  opts = opts or {}
  local patterns = opts.patterns or AGENT_TITLE_PATTERNS
  local key = cache_key(patterns)
  if opts.cache ~= false then
    local cached = agent_surface_cache[key]
    if cached and now_ms() - cached.at <= AGENT_SURFACE_CACHE_TTL_MS then
      return cached.surfaces, cached.err
    end
  end

  local function finish(result, result_err)
    if opts.cache ~= false then
      agent_surface_cache[key] = {
        at = now_ms(),
        surfaces = result,
        err = result_err,
      }
    end
    return result, result_err
  end

  local surfaces, err = list_tree_surfaces()
  if not surfaces then
    surfaces, err = M.list_surfaces()
    if not surfaces then
      return finish(nil, err)
    end
  end

  local me = vim.env.CMUX_SURFACE_ID
  local states, state_labels = read_agent_states()
  local ttys = nil
  local ps = {}
  local matches = {}
  local seen = {}
  local titles = {}
  local screen_candidates = {}
  local function add_match(surface, metadata)
    local ref = M.surface_ref(surface)
    local key_for_surface = ref or tostring(surface.index or surface)
    if metadata and not metadata.tty and ref then
      metadata.tty = surface.tty
      if not metadata.tty then
        ttys = ttys or tree_ttys_by_surface_ref()
        metadata.tty = ttys[ref]
      end
    end
    if metadata and not seen[key_for_surface] then
      seen[key_for_surface] = true
      table.insert(matches, apply_agent_metadata(surface, metadata))
    end
  end

  for _, surface in ipairs(surfaces) do
    if type(surface.title) == "string" then
      table.insert(titles, shorten(surface.title, 40))
    end
    if surface.id ~= me and surface.ref ~= me and not surface.is_current then
      local state = state_for_surface(states, surface)
      local agent = state and (state.agent_title or state.agent_key) or nil
      local metadata = nil
      if state and state_matches(state, patterns) then
        metadata = {
          agent = agent,
          agent_key = state.agent_key,
          status = state.status,
          detail = state.detail,
          tab_title = state.tab_title,
          active = state.active,
          agent_state = state,
          detected_by = "state",
        }
      elseif title_matches(surface.title, patterns) then
        metadata = {
          agent = surface.agent or surface.type,
          detected_by = "title",
        }
      else
        local tty = surface.tty
        if not tty then
          ttys = ttys or tree_ttys_by_surface_ref()
          tty = ttys[M.surface_ref(surface)]
        end
        for _, command in ipairs(ps_commands_for_tty(tty, ps)) do
          local command_agent = detect_agent_from_command(command)
          if agent_matches(command_agent, patterns) then
            metadata = {
              agent = command_agent,
              detected_by = "tty",
              tty = tty,
            }
            break
          end
        end
        if not metadata then
          table.insert(screen_candidates, surface)
        end
      end

      add_match(surface, metadata)
    end
  end

  if #matches == 0 and opts.screen_fallback ~= false then
    local screens = read_surface_screens(screen_candidates)
    for _, surface in ipairs(screen_candidates) do
      local screen_agent = detect_agent_from_screen(screens[surface])
      if agent_matches(screen_agent, patterns) then
        add_match(surface, {
          agent = screen_agent,
          detected_by = "screen",
        })
      end
    end
  end

  if #matches == 0 then
    return finish(
      matches,
      "no cmux agent surfaces among "
        .. tostring(#surfaces)
        .. " surfaces (titles: "
        .. table.concat(titles, ", ")
        .. "; agent states: "
        .. (#state_labels > 0 and table.concat(state_labels, ", ") or "none")
        .. ")"
    )
  end
  return finish(matches, nil)
end

---Discover the Claude Code surface in the current cmux workspace.
---Excludes the caller's own surface. Matches by title containing "Claude Code".
---Returns (ref, nil) on success, (nil, reason) on any structural failure
---(env missing, rpc exit, parse fail) or when no surface matched.
---@return string? surface_ref, string? err
function M.find_claude_surface()
  local surfaces, err = M.list_agent_surfaces({ patterns = { "Claude Code" } })
  if not surfaces then
    return nil, err
  end
  if #surfaces > 0 then
    return M.surface_ref(surfaces[1]), nil
  end
  return nil, err or "no Claude Code surface"
end

---Send text to a cmux surface. Does NOT submit (no trailing Enter).
---@param surface_ref string
---@param text string
---@return boolean ok, string? err
function M.send_text(surface_ref, text)
  local res = vim.system({ cli(), "send", "--surface", surface_ref, "--", text }, { text = true }):wait()
  if res.code ~= 0 then
    return false, (res.stderr or ""):gsub("%s+$", "")
  end
  return true
end

---Press a key in a cmux surface. Key examples: "enter", "escape", "tab".
---@param surface_ref string
---@param key string
---@return boolean ok
function M.send_key(surface_ref, key)
  return vim.system({ cli(), "send-key", "--surface", surface_ref, key }):wait().code == 0
end

return M
