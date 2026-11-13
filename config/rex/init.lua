-- Migrated from tmux (prefix ctrl+space) by Rex.
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })
rex.bind("ctrl+space>shift+r", "client.config.reload")
rex.bind("ctrl+shift+h", "client.tab.previous")
rex.bind("ctrl+shift+l", "client.tab.next")
rex.bind("ctrl+space>q", "client.tab.close")
rex.bind("ctrl+space>x", "pane.close")
rex.bind("ctrl+space>r", "client.tab.rename")
rex.bind("ctrl+space>shift+p", "pane.paste")

local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
local scripts = os.getenv("HOME") .. "/.dotfiles/scripts/rex"

-- The focused pane's directory, like tmux's #{pane_current_path}. The shell
-- doesn't report it to Rex, so ask the foreground process instead.
local function pane_cwd(block_id)
  local proc = rex.block.call(terminal, "process", { block_id = block_id })
  return proc and proc.foreground and proc.foreground.cwd
end

-- New tabs and splits open in the current pane's directory, as in tmux.
rex.action{
  name  = "tab_new_here",
  title = "New Tab Here",
  run   = function(ctx, args)
    local _, err = rex.session.new_window{
      focus  = true,
      layout = rex.layout.block{ flavor = shell, options = { cwd = pane_cwd(ctx.block_id) } },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.action{
  name  = "split_here",
  title = "Split Pane Here",
  args  = { direction = "string" },
  run   = function(ctx, args)
    local _, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = args.direction,
      side      = "after",
      focus     = true,
      layout    = rex.layout.block{ flavor = shell, options = { cwd = pane_cwd(ctx.block_id) } },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("ctrl+space>c", "tab_new_here")
rex.bind("ctrl+space>h", "split_here", { direction = "vertical" })
rex.bind("ctrl+space>v", "split_here", { direction = "horizontal" })

-- Runs one of the scripts above in a floating pane over the focused one. The
-- process is renamed to `name` (exec -a) so the Ctrl-h/j/k/l bindings below
-- recognise it and leave those keys to fzf or Neovim.
local function popup(ctx, name, script, bounds)
  local _, err = rex.session.new_layer{
    bounds = bounds,
    focus  = true,
    layout = rex.layout.block{
      flavor  = shell,
      options = {
        command = {
          "bash", "-c", 'exec -a "$0" bash "$@"', name,
          scripts .. "/" .. script, ctx.session_id or "", ctx.block_id or "",
        },
      },
    },
  }
  if err ~= nil then error(err, 0) end
end

-- Copy mode: the tmux <prefix> [ with vi keys. Opens the pane's scrollback in
-- Neovim in a floating pane; y copies to the system clipboard, q closes.
rex.action{
  name  = "copy_mode",
  title = "Copy Mode",
  run   = function(ctx, args)
    popup(ctx, "copy-mode", "copy-mode.sh", { 0.05, 0.05, 0.9, 0.9 })
  end,
}

rex.bind("ctrl+space>[", "copy_mode")

-- Project picker: the tmux <prefix> f popup. Opens fzf in a floating pane and
-- reopens the current pane in the chosen project directory.
rex.action{
  name     = "project_picker",
  title    = "Find Project…",
  keywords = "fzf sessionizer jump",
  run      = function(ctx, args)
    popup(ctx, "project-picker", "project-picker.sh", { 0.1, 0.1, 0.8, 0.8 })
  end,
}

rex.bind("ctrl+space>f", "project_picker")

-- Sessions, like tmux-sessionx (<prefix> o) and tmux's ( and ).
rex.bind("ctrl+space>o", "session.switch")
rex.bind("ctrl+space>s", "session.switch")
rex.bind("ctrl+space>shift+9", "session.previous")
rex.bind("ctrl+space>shift+0", "session.next")

-- tmux defaults: <prefix> 1-9 selects a tab, <prefix> z zooms the pane.
for i = 1, 9 do
  rex.bind("ctrl+space>" .. i, "client.tab.goto", { index = i })
end
rex.bind("ctrl+space>z", "pane.zoom")

-- vim-tmux-navigator: Ctrl-h/j/k/l moves between panes, but passes the key
-- through when Vim or fzf is in the foreground so they can use it.
local passthrough = {
  vim = true, nvim = true, view = true, vimdiff = true, fzf = true,
  ["project-picker"] = true, ["copy-mode"] = true,
}

for key, direction in pairs{ h = "left", j = "down", k = "up", l = "right" } do
  rex.bind("ctrl+" .. key, function(ctx, ev)
    local proc = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    local fg = proc and proc.foreground
    if fg and (passthrough[fg.name] or passthrough[fg.argv0]) then return false end
    rex.session.focus_direction{ direction = direction }
    return true
  end)
end
