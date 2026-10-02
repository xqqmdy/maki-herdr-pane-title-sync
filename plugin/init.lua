-- Reports the focused session's id and title to the herdr pane maki runs
-- in, so the pane title tracks `/rename` and `--resume` without herdr
-- parsing session logs. Everything is fire-and-forget: a missing or busy
-- herdr must never disturb the editor.

local pane = maki.uv.os_getenv("HERDR_PANE_ID")
local herdr_env = maki.uv.os_getenv("HERDR_ENV")
if not pane or herdr_env ~= "1" then
  return
end

local herdr = maki.uv.os_getenv("HERDR_BIN_PATH") or "herdr"
local SOURCE = "herdr:maki"
local AGENT = "maki"

local function report(args)
  local argv = { herdr, "pane" }
  for _, a in ipairs(args) do
    argv[#argv + 1] = a
  end
  maki.fn.jobstart(argv, {
    stdout = false,
    stderr = false,
    scope = "plugin",
  })
end

local function report_session(id)
  report({
    "report-agent-session",
    pane,
    "--source", SOURCE,
    "--agent", AGENT,
    "--agent-session-id", id,
  })
end

local function report_title(title)
  report({
    "report-metadata",
    pane,
    "--source", SOURCE,
    "--agent", AGENT,
    "--title", title,
  })
end

-- The core's title diff starts seeded with the resumed title, so
-- `maki --resume` never fires SessionTitleChanged; read the title once after
-- the event loop is live. session.read is an async roundtrip, which neither
-- init.lua load nor autocmd dispatch may yield for, so it must run deferred.
local function report_title_of(id)
  maki.defer_fn(function()
    maki.async.run(function()
      local snap = maki.session.read({ session = id })
      local title = snap and snap.title
      if type(title) == "string" and title ~= "" then
        report_title(title)
      end
    end)
  end, 200)
end

maki.api.create_autocmd("SessionFocusChanged", {
  callback = function(ev)
    local id = ev.data and ev.data.session_id
    if id then
      report_session(id)
      report_title_of(id)
    end
  end,
})

maki.api.create_autocmd({ "SessionTitleChanged", "SessionStatusChanged" }, {
  callback = function(ev)
    local d = ev.data or {}
    if d.focused and type(d.title) == "string" and d.title ~= "" then
      report_title(d.title)
    end
  end,
})

-- Covers /reload, where focus already happened before this plugin loaded.
maki.defer_fn(function()
  maki.async.run(function()
    local id = maki.session.current()
    if id then
      report_session(id)
      local snap = maki.session.read({ session = id })
      local title = snap and snap.title
      if type(title) == "string" and title ~= "" then
        report_title(title)
      end
    end
  end)
end, 500)
