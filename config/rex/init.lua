-- Migrated from tmux (prefix ctrl+space) by Rex.
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })
rex.bind("ctrl+space>shift+r", "client.config.reload")
rex.bind("ctrl+shift+h", "client.tab.previous")
rex.bind("ctrl+shift+l", "client.tab.next")
rex.bind("ctrl+space>q", "client.tab.close")
rex.bind("ctrl+space>x", "pane.close")
rex.bind("ctrl+space>c", "client.tab.new")
rex.bind("ctrl+space>h", "pane.split", { direction = "down" })
rex.bind("ctrl+space>v", "pane.split", { direction = "right" })
rex.bind("ctrl+space>r", "client.tab.rename")

-- Project picker: the tmux <prefix> f popup. Opens fzf in a floating pane and
-- reopens the current pane in the chosen project directory.
local project_picker = os.getenv("HOME") .. "/.dotfiles/scripts/rex/project-picker.sh"

rex.action{
  name     = "project_picker",
  title    = "Find Project…",
  keywords = "fzf sessionizer jump",
  run      = function(ctx, args)
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus  = true,
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = {
          -- exec -a names the process so the Ctrl-h/j/k/l bindings below
          -- recognise the picker and leave those keys to fzf.
          command = {
            "bash", "-c", 'exec -a project-picker bash "$@"', "bash",
            project_picker,
            ctx.session_id or "",
            ctx.block_id or "",
          },
        },
      },
    }
    if err ~= nil then error(err, 0) end
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
  ["project-picker"] = true,
}

for key, direction in pairs{ h = "left", j = "down", k = "up", l = "right" } do
  rex.bind("ctrl+" .. key, function(ctx, ev)
    local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    local fg = proc and proc.foreground
    if fg and (passthrough[fg.name] or passthrough[fg.argv0]) then return false end
    rex.session.focus_direction{ direction = direction }
    return true
  end)
end
