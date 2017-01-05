--[[
- awesomeWM 4.0 configuration
- github@tdy/awesome
--]]

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
beautiful.init(awful.util.getdir("config") .. "/themes/dust/theme.lua")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local vicious = require("vicious")
local scratch = require("scratch")
local wi = require("wi")

-- {{{ Error handling
-- Startup
if awesome.startup_errors then
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors
  })
end

-- Runtime
do
  local in_error = false
  awesome.connect_signal("debug::error",
    function(err)
      if in_error then return end
      in_error = true

      naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, an error happened!",
        text = tostring(err)
      })
      in_error = false
    end
  )
end
-- }}}

-- {{{ Variables
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

pianobar_cmd      = os.getenv("HOME") .. "/.config/pianobar/control-pianobar.sh "
pianobar_toggle   = pianobar_cmd .. "p"
pianobar_next     = pianobar_cmd .. "n"
pianobar_like     = pianobar_cmd .. "l"
pianobar_ban      = pianobar_cmd .. "b"
pianobar_tired    = pianobar_cmd .. "t"
pianobar_history  = pianobar_cmd .. "h"
pianobar_upcoming = pianobar_cmd .. "u"
pianobar_station  = pianobar_cmd .. "ss"
pianobar_playing  = pianobar_cmd .. "c"
pianobar_quit     = pianobar_cmd .. "q && screen -S pianobar -X quit"
pianobar_screen   = "screen -Sdm pianobar && screen -S pianobar -X screen " .. pianobar_toggle

modkey = "Mod4"
altkey = "Mod1"
-- }}}

-- {{{ Layouts
awful.layout.layouts = {
  awful.layout.suit.floating,
  awful.layout.suit.tile,
  awful.layout.suit.tile.left,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  awful.layout.suit.fair,
  awful.layout.suit.fair.horizontal,
  awful.layout.suit.spiral,
  awful.layout.suit.spiral.dwindle,
  awful.layout.suit.max,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.magnifier,
  awful.layout.suit.corner.nw,
  awful.layout.suit.corner.ne,
  awful.layout.suit.corner.sw,
  awful.layout.suit.corner.se
}
-- }}}

-- {{{ Notifications
naughty.config.defaults.timeout = 5
naughty.config.defaults.screen = 1
naughty.config.defaults.position = "top_right"
naughty.config.defaults.margin = 8
naughty.config.defaults.gap = 1
naughty.config.defaults.ontop = true
naughty.config.defaults.font = "terminus 12"
naughty.config.defaults.icon = nil
naughty.config.defaults.icon_size = 256
naughty.config.defaults.fg = beautiful.fg_tooltip
naughty.config.defaults.bg = beautiful.bg_tooltip
naughty.config.defaults.border_color = beautiful.border_tooltip
naughty.config.defaults.border_width = 2
naughty.config.defaults.hover_timeout = nil
-- }}}

-- {{{ Helpers
local function client_menu_toggle_fn()
  local instance = nil

  return
    function()
      if instance and instance.wibox.visible then
        instance:hide()
        instance = nil
      else
        instance = awful.menu.clients({
          theme = { width = 250 }
        })
      end
    end
end
-- }}}

-- {{{ Power
mylauncher = wibox.widget.imagebox()
mylauncher:set_image(beautiful.awesome_icon)
mylauncher:buttons(awful.util.table.join(
  -- Lock
  awful.button({ }, 1,
    function()
      local lock = "i3lock -d -p default -c " .. beautiful.bg_focus:gsub("#","")
      awful.util.spawn(lock, false)
    end
  ),
  -- Reboot
  awful.button({ modkey }, 1,
    function()
      local reboot = "zenity --question --text 'Reboot?' && systemctl reboot"
      awful.util.spawn(reboot, false)
    end
  ),
  -- Shutdown
  awful.button({ modkey }, 3,
    function()
      local shutdown = "zenity --question --text 'Shut down?' && systemctl poweroff"
      awful.util.spawn(shutdown, false)
    end
  )
))

menubar.utils.terminal = terminal
-- }}}

-- {{{ Wallpaper
local function set_wallpaper(s)
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)
  end
end
screen.connect_signal("property::geometry", set_wallpaper)
-- }}}

-- {{{ Tags
tags = {
  names = { "01", "02", "03", "04", "05", "06", "07", "08", "09", "10" },
  layouts = {
    awful.layout.layouts[2],
    awful.layout.layouts[10],
    awful.layout.layouts[2],
    awful.layout.layouts[2],
    awful.layout.layouts[2],
    awful.layout.layouts[1],
    awful.layout.layouts[10],
    awful.layout.layouts[1],
    awful.layout.layouts[1],
    awful.layout.layouts[1]
  }
}
-- }}}

mykeyboardlayout = awful.widget.keyboardlayout()
mytextclock = wibox.widget.textclock(
  "<span color='" .. beautiful.fg_em .. "'>%a %m/%d</span> @ %I:%M %p"
)

-- {{{ Initialize wiboxes
mywibox = {}
mygraphbox = {}
mypromptbox = {}
mylayoutbox = {}

-- Taglist
local taglist_buttons = awful.util.table.join(
  awful.button({ }, 1, function(t) t:view_only() end),
  awful.button({ modkey }, 1,
    function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
    end
  ),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3,
    function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
    end
  ),
  awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- Tasklist
local tasklist_buttons = awful.util.table.join(
  awful.button({ }, 1,
    function(c)
      if c == client.focus then
          c.minimized = true
      else
        c.minimized = false
        if not c:isvisible() and c.first_tag then
          c.first_tag:view_only()
        end
        client.focus = c
        c:raise()
      end
    end
  ),
  awful.button({ }, 3, client_menu_toggle_fn()),
  awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
  awful.button({ }, 5, function() awful.client.focus.byidx(-1) end))
-- }}}

-- {{{ Create wiboxes
awful.screen.connect_for_each_screen(
  function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Taglist
    awful.tag(tags.names, s, tags.layouts)
    s.mytaglist = awful.widget.taglist(
      s, awful.widget.taglist.filter.all, taglist_buttons
    )

    -- Promptbox
    s.mypromptbox = awful.widget.prompt()

    -- Layoutbox
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
      awful.button({ }, 1, function() awful.layout.inc(1) end),
      awful.button({ }, 3, function() awful.layout.inc(-1) end),
      awful.button({ }, 4, function() awful.layout.inc(1) end),
      awful.button({ }, 5, function() awful.layout.inc(-1) end)
    ))

    -- Tasklist
    s.mytasklist = awful.widget.tasklist(
      s, awful.widget.tasklist.filter.currenttags, tasklist_buttons
    )

    -- Wibox
    local left_wibox = wibox.layout.fixed.horizontal()
    left_wibox:add(s.mytaglist)
    left_wibox:add(space)
    left_wibox:add(s.mypromptbox)
    left_wibox:add(s.mylayoutbox)
    left_wibox:add(space)

    local right_wibox = wibox.layout.fixed.horizontal()
    right_wibox:add(wibox.widget.systray())
    right_wibox:add(mykeyboardlayout)
    right_wibox:add(mpdicon)
    right_wibox:add(mpdwidget)
    right_wibox:add(pacicon)
    right_wibox:add(pacwidget)
    right_wibox:add(baticon)
    right_wibox:add(batpct)
    right_wibox:add(volicon)
    right_wibox:add(volpct)
    right_wibox:add(volspace)

    local wibox_layout = wibox.layout.align.horizontal()
    wibox_layout:set_left(left_wibox)
    wibox_layout:set_middle(s.mytasklist)
    wibox_layout:set_right(right_wibox)

    s.mywibox = awful.wibar({ position = "top", height = 16, screen = s })
    s.mywibox:set_widget(wibox_layout)

    -- Graphbox
    local left_graphbox = wibox.layout.fixed.horizontal()
    left_graphbox:add(mylauncher)
    left_graphbox:add(space)
    left_graphbox:add(cpufreq)
    left_graphbox:add(cpugraph0)
    left_graphbox:add(cpupct0)
    left_graphbox:add(tab)
    left_graphbox:add(memused)
    left_graphbox:add(membar)
    left_graphbox:add(mempct)
    left_graphbox:add(tab)
    left_graphbox:add(rootfsused)
    left_graphbox:add(rootfsbar)
    left_graphbox:add(rootfspct)
    left_graphbox:add(tab)
    left_graphbox:add(txwidget)
    left_graphbox:add(txgraph)
    left_graphbox:add(upwidget)
    left_graphbox:add(tab)
    left_graphbox:add(rxwidget)
    left_graphbox:add(rxgraph)
    left_graphbox:add(dnwidget)

    local right_graphbox = wibox.layout.fixed.horizontal()
    right_graphbox:add(weather)
    right_graphbox:add(space)
    right_graphbox:add(mytextclock)
    right_graphbox:add(space)

    local graphbox_layout = wibox.layout.align.horizontal()
    graphbox_layout:set_left(left_graphbox)
    graphbox_layout:set_right(right_graphbox)

    s.mygraphbox = awful.wibar({ position = "bottom", height = 12, screen = s })
    s.mygraphbox:set_widget(graphbox_layout)
  end
)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
  awful.button({ }, 4, awful.tag.viewnext),
  awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
  -- Popups
  awful.key({ modkey }, "s", hotkeys_popup.show_help),

  -- Tag navigation
  awful.key({ modkey }, "Left", awful.tag.viewprev),
  awful.key({ modkey }, "Right", awful.tag.viewnext),
  awful.key({ modkey }, "Escape", awful.tag.history.restore),

  -- Client navigation
  awful.key({ altkey }, "Tab",
    function()
      awful.client.focus.byidx(1)
      if client.focus then client.focus:raise() end
    end
  ),
  awful.key({ altkey, "Shift" }, "Tab",
    function()
      awful.client.focus.byidx(-1)
      if client.focus then client.focus:raise() end
    end
  ),

  -- Layout manipulation
  awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx(1) end),
  awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end),
  awful.key({ modkey }, "Tab", function() awful.screen.focus_relative(1) end),
  awful.key({ modkey, "Shift" }, "Tab", function() awful.screen.focus_relative(-1) end),
  awful.key({ modkey }, "u", awful.client.urgent.jumpto),
  awful.key({ modkey }, "p",
    function()
      awful.client.focus.history.previous()
      if client.focus then client.focus:raise() end
    end
  ),

  -- Standard program
  awful.key({ modkey }, "Return", function() awful.spawn(terminal) end),
  awful.key({ modkey, "Control" }, "r", awesome.restart),
  awful.key({ modkey, "Shift" }, "q", awesome.quit),
  awful.key({ modkey }, "l", function() awful.tag.incmwfact(0.05) end),
  awful.key({ modkey }, "h", function() awful.tag.incmwfact(-0.05) end),
  awful.key({ modkey }, "k", function() awful.client.incwfact(0.03) end),
  awful.key({ modkey }, "j", function() awful.client.incwfact(-0.03) end),
  awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end),
  awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end),
  awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1, nil, true) end),
  awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end),
  awful.key({ modkey }, "space", function() awful.layout.inc(1) end),
  awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end),
  awful.key({ modkey, "Control" }, "n",
    function()
      local c = awful.client.restore()
      if c then
        client.focus = c
        c:raise()
      end
    end
  ),

  -- Scratch
  awful.key({ modkey }, "`",
    function()
      scratch.drop('urxvtc -name scratch', "bottom", "center", 1.0, 0.40, false)
    end
  ),

  -- Prompts
  awful.key({ altkey }, "F2", function() awful.screen.focused().mypromptbox:run() end),
  awful.key({ modkey }, "x",
    function()
      awful.prompt.run {
        prompt = "Run Lua code: ",
        textbox = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
    end
  ),
  awful.key({ modkey }, "r", function() menubar.show() end),

  -- Pianobar
  awful.key({ modkey }, "XF86AudioPrev", function() awful.util.spawn(pianobar_history, false) end),
  awful.key({ modkey }, "XF86AudioNext", function() awful.util.spawn(pianobar_next, false) end),
  awful.key({ modkey, "Shift" }, "XF86AudioPlay", function() awful.util.spawn(pianobar_quit, false) end),
  awful.key({ modkey }, "XF86AudioPlay",
    function()
      local f = io.popen("pgrep pianobar")
      p = f:read("*line")
      if p then
        awful.util.spawn(pianobar_toggle, false)
      else
        awful.util.spawn(pianobar_screen, false)
      end
    end
  ),
  awful.key({ modkey }, "'",
    function()
      local f = io.popen("pgrep pianobar")
      p = f:read("*line")
      if not p then awful.util.spawn_with_shell(pianobar_screen) end
      scratch.drop("xterm -name pianobar -e 'screen -x pianobar'", "top", "center", 0.5, 0.2, false)
    end
  ),
  awful.key({ modkey }, "=", function() awful.util.spawn(pianobar_like, false) end),
  awful.key({ modkey }, "-", function() awful.util.spawn(pianobar_ban, false) end),
  awful.key({ modkey, "Shift" }, "-", function() awful.util.spawn(pianobar_tired, false) end),
  awful.key({ modkey }, "[", function() awful.util.spawn(pianobar_station, false) end),
  awful.key({ modkey }, "]", function() awful.util.spawn(pianobar_upcoming, false) end),
  awful.key({ modkey }, "\\", function() awful.util.spawn(pianobar_playing, false) end)
)

clientkeys = awful.util.table.join(
  awful.key({ modkey }, "f",
    function(c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end
  ),
  awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end),
  awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle),
  awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end),
  awful.key({ modkey }, "o", function(c) c:move_to_screen() end),
  awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end),
  awful.key({ modkey }, "n", function(c) c.minimized = true end),
  awful.key({ modkey }, "m",
    function(c)
      c.maximized = not c.maximized
      c:raise()
    end
  ),

  -- Scratchify
  awful.key({ modkey }, "v", function(c) scratch.pad.set(c, 0.50, 0.50, true) end)
)

for i = 1, 10 do
  globalkeys = awful.util.table.join(globalkeys,
    awful.key({ modkey }, "#" .. i + 9,
      function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          tag:view_only()
        end
      end
    ),
    awful.key({ modkey, "Control" }, "#" .. i + 9,
      function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end
    ),
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
      function()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:move_to_tag(tag)
          end
        end
      end
    ),
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
      function()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:toggle_tag(tag)
          end
        end
      end
    )
  )
end

clientbuttons = awful.util.table.join(
  awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
  -- All clients
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen,
      size_hints_honor = false
    }
  },

  -- Floating clients
  {
    rule_any = {
      instance = {
        "Download",
        "Browser",
        "Toplevel",
        "Places"
      },
      class = {
        "Skype",
        "mpv",
        "pinentry",
        "Gimp-2.8",
        "xtightvncviewer"
      },
      name = {
        "Event Tester" -- xev
      },
      role = {
        "AlarmWindow", -- Thunderbird calendar
        "pop-up" -- Google Chrome developer tools (detached)
      }
    },
    properties = { floating = true }
  },

  -- Tagged clients
  {
    rule = { class = "Skype" },
    properties = { screen = 1, tag = "1" }
  },
  {
    rule = { class = "Firefox" },
    properties = { screen = 1, tag = "2" }
  },
  {
    rule = { class = "Thunar" },
    properties = { screen = 1, tag = "7" }
  },
  {
    rule = { class = "Gimp-2.8" },
    properties = { screen = 1, tag = "8" }
  }
}
-- }}}

-- {{{ Signals
-- Positioning
client.connect_signal("manage",
  function(c)
    if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_offscreen(c)
    end
  end
)

-- Titlebar if requested
client.connect_signal("request::titlebars",
  function(c)
    local buttons = awful.util.table.join(
      awful.button({ }, 1,
        function()
          client.focus = c
          c:raise()
          awful.mouse.client.move(c)
        end
      ),
      awful.button({ }, 3,
        function()
          client.focus = c
          c:raise()
          awful.mouse.client.resize(c)
        end
      )
    )

    awful.titlebar(c):setup {
      -- Left
      {
        awful.titlebar.widget.iconwidget(c),
        buttons = buttons,
        layout  = wibox.layout.fixed.horizontal
      },
      -- Middle
      {
        {
          align  = "center",
          widget = awful.titlebar.widget.titlewidget(c)
        },
        buttons = buttons,
        layout  = wibox.layout.flex.horizontal
      },
      -- Right
      {
        awful.titlebar.widget.floatingbutton(c),
        awful.titlebar.widget.maximizedbutton(c),
        awful.titlebar.widget.stickybutton(c),
        awful.titlebar.widget.ontopbutton(c),
        awful.titlebar.widget.closebutton(c),
        layout = wibox.layout.fixed.horizontal()
      },
      layout = wibox.layout.align.horizontal
    }
  end
)

-- Sloppy focus
client.connect_signal("mouse::enter",
  function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and awful.client.focus.filter(c) then
      client.focus = c
    end
  end
)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim: ft=lua ts=2 sts=2 sw=2 et
