------------------------------------------------------------
--  FEATURE TOGGLES
------------------------------------------------------------
local features = {
    debug       = false,
    autoReload  = true,
    textEditing = true,
    dateTime    = true,
    spotify     = true,
    location    = false,
    archobs     = true,
    krisp       = true,
    keyCaster   = true,
    myCaster    = false, -- see helpers
}
-------------------------------------------------------------
-- MODIFIERS
------------------------------------------------------------
local cmd    = {"cmd"}
local shift  = {"shift"}
local option = {"option"}
local ctrl   = {"ctrl"}

-- two
local shift_cmd    = {"shift", "cmd"}
local option_cmd   = {"option", "cmd"}
local ctrl_cmd     = {"ctrl", "cmd"}
local option_shift = {"option", "shift"}
local ctrl_shift   = {"ctrl", "shift"}
local ctrl_option  = {"ctrl", "option"}

-- three
local option_shift_cmd = {"option", "shift", "cmd"}
local ctrl_shift_cmd   = {"ctrl", "shift", "cmd"}
local mash             = {"ctrl", "option", "cmd"}      -- aka ctrl_option_cmd
local meh              = {"ctrl", "option", "shift"}    -- aka ctrl_option_shift

-- four
local hyper = {"ctrl", "option", "shift", "cmd"}

------------------------------------------------------------
-- DEBUG TOOLS
------------------------------------------------------------
-- Clear Hammerspoon Console
if features.debug then
    hs.hotkey.bind(option, "c", function()
    hs.console.clearConsole()
    end)
end

-- MANUAL-RELOAD
if features.debug then
    hs.hotkey.bind(option, "r", function()
        -- Force KeyCaster to stop (same as auto-reload)
        if spoon and spoon.KeyCaster then
            pcall(function() spoon.KeyCaster:stop() end)
        end

        hs.alert.show("Manual Reload")
        hs.timer.doAfter(0.1, function()
            hs.reload()
        end)
    end)
end


------------------------------------------------------------
-- AUTO-RELOAD
------------------------------------------------------------
if features.autoReload then
    -- Use a global so it survives better across reloads
    _G.configWatcher = _G.configWatcher or nil

    local function reloadConfig(files)
        -- for debug
        -- print("pathwatcher fired →", hs.inspect(files))
        local doReload = false
        for _, file in pairs(files) do
            if file:sub(-4) == ".lua" then
                doReload = true
                break
            end
        end
        if doReload then
            -- Force KeyCaster to stop
            if spoon and spoon.KeyCaster then
                pcall(function() spoon.KeyCaster:stop() end)
            end
            -- Give the system a tiny moment to settle
            hs.timer.doAfter(0.1, function()
                hs.reload()
            end)
        end
    end

    -- Tear down any existing watcher
    if _G.configWatcher then
        pcall(function() _G.configWatcher:stop() end)
        _G.configWatcher = nil
    end

    -- Watch the specific file instead of the whole directory (often more reliable)
    _G.configWatcher = hs.pathwatcher.new(
        os.getenv("HOME") .. "/.hammerspoon/init.lua",
        reloadConfig
    ):start()
end


------------------------------------------------------------
--  HELPERS
------------------------------------------------------------
-- Paste a string while preserving the original clipboard
local function pastePreservingClipboard(str, delay)
    delay = delay or 0.15
    local temp = hs.pasteboard.uniquePasteboard()
    hs.pasteboard.writeAllData(temp, hs.pasteboard.readAllData(nil))

    hs.pasteboard.setContents(str)
    hs.eventtap.keyStroke(cmd, "v")

    hs.timer.doAfter(delay, function()
        hs.pasteboard.writeAllData(nil, hs.pasteboard.readAllData(temp))
        hs.pasteboard.deletePasteboard(temp)
    end)
end

-- KeyCaster helper that forces the next push to start a new box
local function forceNewBox()
    if not spoon.KeyCaster then return end
    if spoon.KeyCaster._currentGroup then
        spoon.KeyCaster._currentGroup.lastTouch = 0   -- make it look very old
    end
end

-- KeyCaster helper to push text to KeyCaster (works even if not started)
local function keyCasterShow(text)
    if features.myCaster then
        if not spoon.KeyCaster then return end

        -- Make sure basic state exists
        if not spoon.KeyCaster._resolvedFont then
            spoon.KeyCaster:_resolveFont()
        end

        if spoon.KeyCaster.config.mode == "line" then
            spoon.KeyCaster:_linePush(text)
        else
            spoon.KeyCaster:_columnPush(text)
        end
        forceNewBox()
    end
end

--[[ example custom string in KeyCaster 
-- the heart of the above keyCasterShow function ☝️ 
hs.hotkey.bind(hyper, "space", function()
    if not spoon.KeyCaster then return end
    local text = "example"
    if spoon.KeyCaster.config.mode == "line" then
        spoon.KeyCaster:_linePush(text)
    else
        spoon.KeyCaster:_columnPush(text)
    end
end)
]]


------------------------------------------------------------
--  🚧 TEST FACILIYT 🚧TEST
------------------------------------------------------------

-- Custom alert style
hs.hotkey.bind(ctrl_cmd, "space", function()
hs.alert.show("This Is A Test", 5.0, {
    fillColor = { red = 1, green = 0, blue = 0, alpha = 1 },
    strokeColor = { white = 1, alpha = 1 },
    strokeWidth = 10,
    textColor = { white = 1, alpha = 1 },
})
end)




------------------------------------------------------------
--  KeyCaster.spoon
------------------------------------------------------------
-- Toggle myCaster
local myState = "OFF"

hs.hotkey.bind(mash, "m", function()
    features.myCaster = not features.myCaster
    myState = features.myCaster and "ON" or "OFF"
    keyCasterShow(" 🥄Caster ".. myState)
    print("myCaster →", myState)
    if myState == "OFF" then
    spoon.KeyCaster:stop()
    end
end)
-- KeyCaster Configuration
if features.keyCaster then
    if hs.loadSpoon("KeyCaster") then
        -- Customize the labels KeyCaster shows
        spoon.KeyCaster.specialKeys["tab"] = " tab "
        -- spoon.KeyCaster.specialKeys["escape"] = "Escape"
        spoon.KeyCaster
        :configure({
          -- Core
          mode = "column",               -- "column" | "line"
          line = { fadeMode = "time" },  -- uses fadingDuration
          fadingDuration = 8.0,
          --maxVisible = 0,
          maxVisible = 2,
          minAlphaWhileVisible = .65,
          followInterval = 0.40,
          ignoreAutoRepeat = true,

          -- Free placement (drag with ⌘⌥ to move)
          positionFree = { x = 1322, y = 793 },  -- top-left anchor (px)

          -- Appearance
          font = { name = "Menlo", size = 24 },
          colors = {
            bg     = { red=0, green=0, blue=0, alpha=0.78 },
            text   = { red=255, green=0, blue=0, alpha=0.95 },
            stroke = { red=1, green=1, blue=1, alpha=0.15 },
            shadow = { red=0, green=0, blue=0, alpha=0.6 },
          },

          -- Column mode
          box = { w = 300, h = 42, spacing = 8, corner = 10 },
          column = {
            newBoxOnPause = 0.70,
            fillMode      = "measure",  -- pixel-based packing (measure or chars)
            fillFactor    = 0.96,       -- new box when measured width > 96% of usable width
            hardGrouping  = true,       -- never split labels across boxes
            groupJoiner   = "",         -- "" for tight (e.g. ⌘C), " " or " " for spacing
            -- maxCharsPerBox is used only if you set fillMode="chars"
          },

          -- Line mode
          line = {
            box = { w = 520, h = 36, corner = 10 },
            maxSegments = 60,
            gap = 6,
            fadeMode = "overflow",      -- "overflow" = no time fade; trim when off-box, or "time"
            joiner = nil,                -- nil = reuse column.groupJoiner; "" or " " to override
          },

          -- Optional safety & filters
          respectSecureInput = true,    -- suppress while macOS secure input is active
          appFilter = nil,              -- e.g., { mode="deny", bundleIDs={"com.agilebits.onepassword7"} }
          showModifierOnly = true,     -- if true, show pure modifier chords (e.g., ⌘⇧)
          showMouse = { enabled = false, radius = 14, fade = 0.6, strokeAlpha = 0.35 }, -- click ripples
        })
        -- :bindHotkeys(spoon.KeyCaster.defaultHotkeys) -- K and F
        :bindHotkeys({
            start = { mash, "v" },
            stop  = { mash, "b" },
        })
        -- spoon.KeyCaster:start()   -- or bind a hotkey to toggle it
        
        -- Wrap the start method so it shows a message when activated
        local originalStart = spoon.KeyCaster.start
        function spoon.KeyCaster:start()
            originalStart(self)
            if features.myCaster then
                keyCasterShow(" 🔨Caster ON")
            else
                hs.alert.show("🔨Caster: ON")
            end
        end

        local originalStop = spoon.KeyCaster.stop
        function spoon.KeyCaster:stop()
            originalStop(self)
            hs.alert.show("🔨🥄Caster: OFF")
        end
    end
end


------------------------------------------------------------
--  TEXT EDITING / DELETE KEYS
------------------------------------------------------------
if features.textEditing then
    -- VIM-style Escape
    hs.hotkey.bind(shift, "forwarddelete", function()
        hs.eventtap.keyStroke({}, "escape")
        keyCasterShow(" VIM Escape")
    end)

    -- FocusWriter workaround for Cmd + Backspace
    hs.hotkey.bind(shift_cmd, "delete", function()
        hs.eventtap.keyStroke(shift_cmd, "left")
        hs.eventtap.keyStroke({}, "delete")
    end)

    -- Forward delete by word
    hs.hotkey.bind(option, "forwarddelete", function()
        hs.eventtap.keyStroke(option_shift, "right")
        hs.eventtap.keyStroke({}, "delete")
        keyCasterShow(" fwd.Select Word")
    end)

    -- Forward delete by line
    hs.hotkey.bind(cmd, "forwarddelete", function()
        hs.eventtap.keyStroke(shift_cmd, "right")
        hs.eventtap.keyStroke({}, "delete")
        keyCasterShow(" fwd.Select Line")
    end)

    -- Left-hand delete (Cmd + Option + Forward Delete)
    hs.hotkey.bind(option_cmd, "forwarddelete", function()
        hs.eventtap.keyStroke(cmd, "delete")
        keyCasterShow(" lft.Hand Delete")
    end)

    -- Left-hand backspace (Ctrl + Forward Delete)
    hs.hotkey.bind(ctrl, "forwarddelete", function()
        hs.eventtap.keyStroke({}, "delete")
        keyCasterShow(" lft.Hand Bkspc")
    end)
end


------------------------------------------------------------
--  DATE, TIME, & Location
------------------------------------------------------------
if features.dateTime then
    -- Current time
    hs.hotkey.bind(mash, "u", function()
        pastePreservingClipboard(os.date("%I:%M%p "))
        keyCasterShow(" Current Time")
    end)

    -- Current date
    hs.hotkey.bind(mash, "l", function()
        pastePreservingClipboard(os.date("%Y-%m-%d "))
        keyCasterShow(" Current Date")
    end)

    -- .md time
    hs.hotkey.bind(hyper, "u", function()
        pastePreservingClipboard("## " .. os.date("%I:%M%p "))
        keyCasterShow(" .md Time")
    end)

    -- .md date
    hs.hotkey.bind(hyper, "l", function()
        pastePreservingClipboard("# " .. os.date("%Y-%m-%d "))
        keyCasterShow(" .md Date")
    end)

    -- ex. 2026-08-13 10:05PM ~ JH
    hs.hotkey.bind(hyper, "j", function()
        local stamp = os.date("%Y-%m-%d %I:%M%p ") .. "~ JH"
        pastePreservingClipboard("-- " .. stamp)
    end)
    -- Fetch Location (I cannot believe this works)
    hs.hotkey.bind(mash, "e", function()
        hs.eventtap.keyStroke(ctrl_shift_cmd, "L")
        keyCasterShow(" Location")
    end)
end


------------------------------------------------------------
--  SPOTIFY
------------------------------------------------------------
if features.spotify then
    -- Rewind 15s
    hs.hotkey.bind(mash, "left", function()
        hs.spotify.setPosition(hs.spotify.getPosition() - 15)
    end)

    -- Fast-forward 10s
    hs.hotkey.bind(mash, "right", function()
        hs.spotify.setPosition(hs.spotify.getPosition() + 10)
    end)

    -- Artist – Title
    hs.hotkey.bind(mash, "up", function()
        local text = hs.spotify.getCurrentArtist() .. " – " .. hs.spotify.getCurrentTrack()
        pastePreservingClipboard(text)
        keyCasterShow(" Art. – Track")
    end)

    -- Title – Artist
    hs.hotkey.bind(hyper, "up", function()
        local text = hs.spotify.getCurrentTrack() .. " – " .. hs.spotify.getCurrentArtist()
        pastePreservingClipboard(text)
        keyCasterShow(" Track – Art.")
    end)

        -- → fxspotify.com link
    hs.hotkey.bind(mash, "down", function()
        local uri = hs.spotify.getCurrentTrackId()
        local trackId = string.gsub(uri or "", "^[^:]*:[^:]*:", "")
        pastePreservingClipboard("https://fxspotify.com/track/" .. trackId)
        keyCasterShow(" Spotify Link")
    end)

    -- Track ID
    hs.hotkey.bind(hyper, "down", function()
        pastePreservingClipboard(hs.spotify.getCurrentTrackId())
        keyCasterShow(" Track ID")
    end)

    -- → song.link
    hs.hotkey.bind(mash, "=", function()
        local uri = hs.spotify.getCurrentTrackId()
        local trackId = string.gsub(uri or "", "^[^:]*:[^:]*:", "")
        pastePreservingClipboard("https://song.link/s/" .. trackId)
        keyCasterShow(" Universal Link")

    end)
end


------------------------------------------------------------
--  KRISP TOGGLE (Discord)
------------------------------------------------------------
if features.krisp then
    local function toggleKrisp()
        if not hs.application.find("Discord") then
            hs.notify.new({title = "Toggle Krisp Failed", informativeText = "You're not even on Discord you idiot 🤦‍♀️"}):send()
            return
        end
        hs.application.launchOrFocus("Discord")
        hs.timer.usleep(80000)
        hs.osascript.applescript('do shell script "/opt/homebrew/bin/cliclick -w 500 m:310,940 c:310,940 m:400,680 c:400,680 kp:esc"')
        hs.notify.new({title = "Hammerspoon", informativeText = "Toggled Krisp"}):send()
    end
    hs.hotkey.bind(hyper, "k", toggleKrisp)
end


------------------------------------------------------------
--[[ 🪦GRAVEYARD🪦  (disabled / old experiments)
------------------------------------------------------------
-- Left hand Mission Control + space switching
    -- This part works to get in and out of mission control
    hs.hotkey.bind(ctrl_cmd, "x", function()
        hs.spaces.toggleMissionControl()
    end)
-- Next / Previous space via system shortcuts (never worked, some issue with trying to spoof ctrl somehow triggering option or command)
    -- First Attempt 2025-12-13 (moved to Karabiner
    hs.hotkey.bind(ctrl_cmd, "c", function()
        hs.eventtap.keyStroke(ctrl, "right")
    end)
    hs.hotkey.bind(ctrl_cmd, "z", function()
        hs.eventtap.keyStroke(ctrl, "left")
    end)
        -- Second Attempt 2026-08-13 
        --hs.hotkey.bind(ctrl_cmd, "c", function()
        --    hs.eventtap.keyStroke(ctrl, "right", 0)   -- 0 = no delay
        --end)
        --hs.hotkey.bind(ctrl_cmd, "z", function()
        --    hs.eventtap.keyStroke(ctrl, "left", 0)
        --end)
-- This part works but the animation is too much for me
local function switchSpace(direction)  -- +1 = next, -1 = previous
    local screen = hs.screen.mainScreen()
    local spaces = hs.spaces.spacesForScreen(screen)
    local current = hs.spaces.activeSpaceOnScreen(screen)

    for i, id in ipairs(spaces) do
        if id == current then
            local target = spaces[i + direction]
            if target then
                hs.spaces.gotoSpace(target)
            end
            break
        end
    end
end

hs.hotkey.bind(ctrl_cmd, "c", function() switchSpace(1) end)   -- next
hs.hotkey.bind(ctrl_cmd, "z", function() switchSpace(-1) end)  -- previous


------------------------------------------------------------
--  LOCATION (CoreLocationCLI) UNTESTED  ⚠️ V.2 Refactored by Grok 2026-08-14
-- Replace by a mocOS shortcut assinged to ctrl_shift_cmd, "L"
-- Stopped using because the CoreLocationCLI.app is self signed and requires bypassing Gatekeeper
-- https://github.com/fulldecent/corelocationcli
if features.location then
    hs.hotkey.bind(mash, "e", function()
        -- Fetch everything in one go (faster + consistent snapshot)
        local latlon       = hs.execute(CoreLocationCLI -f "%latitude %longitude", true) or ""
        local locality     = hs.execute(CoreLocationCLI -f "%locality %administrativeArea %country", true) or ""
        local thoroughfare = hs.execute(CoreLocationCLI -f "%thoroughfare", true) or ""

        -- Clean up trailing newlines that CoreLocationCLI sometimes adds
        latlon       = latlon:gsub("%s+$", "")
        locality     = locality:gsub("%s+$", "")
        thoroughfare = thoroughfare:gsub("%s+$", "")

        -- Build the final block
        local block = string.format(
            "%s\n%s\n@%s\n___\n\n",
            latlon,
            locality,
            thoroughfare
        )

        -- Paste it in one shot (uses your existing helper)
        pastePreservingClipboard(block)

        keyCasterShow(" Location")
    end)
end


------------------------------------------------------------
--  ARCHOBS (Markdown → embed)
if features.archobs then
    hs.hotkey.bind(hyper, "O", function()
        local clipboardContent = hs.pasteboard.getContents()
        local command = '/Users/user/bin/archobs "' .. (clipboardContent or "") .. '"'

        hs.console.printStyledtext("Running command: " .. command)
        local output, status = hs.execute(command)

        if output then
            hs.pasteboard.setContents(output)
            hs.console.printStyledtext("Output: " .. output)
            hs.timer.doAfter(1, function()
                hs.eventtap.keyStroke(cmd, "v")
            end)
        else
            hs.console.printStyledtext("Command failed: " .. tostring(status))
        end
    end)
end


------------------------------------------------------------
-- test to reset mouse position
hs.hotkey.bind(shift_cmd, "r", function()
    hs.execute("cliclick m:960,540", true)
end)


------------------------------------------------------------
-- Multi-line string test
MULTILINE_STRING = [[multi
line
string
hs.hotkey.bind(ctrl_cmd, "1", function()
    -- old clipboard method...
end)


------------------------------------------------------------
-- Skip YouTube ad
hs.hotkey.bind(ctrl_cmd, "return", function()
    hs.execute("cliclick m:1835,950", true)
    hs.execute("cliclick w:50", true)
    hs.execute("cliclick c:1835,950", true)
end)


------------------------------------------------------------
-- kanata Siri
hs.hotkey.bind(hyper, "f5", function()
    hs.eventtap.keyStroke({"fn"}, "space")
end)


------------------------------------------------------------
-- Launchpad (Sequoia and earlier)
hs.hotkey.bind(hyper, "l", function()
    hs.execute("open -a Launchpad", true)
end)


------------------------------------------------------------
-- FadeLogo spoon
hs.loadSpoon("FadeLogo")
spoon.FadeLogo.zoom_scale_factor = 1.1
spoon.FadeLogo.fade_in_time = 0
spoon.FadeLogo.fade_out_time = 0.1
spoon.FadeLogo.image_alpha = 1
spoon.FadeLogo:start()


------------------------------------------------------------
-- Custom alert style
hs.alert.show("config loaded", 0.75, {
    fillColor = { red = .8, green = .7, blue = 0, alpha = 1 },
    strokeColor = { white = 0, alpha = 1 },
    strokeWidth = 5,
    textColor = { white = 0, alpha = 1 },
})


------------------------------------------------------------
]]-- END 🪦GRAVEYARD🪦
------------------------------------------------------------
--  STARTUP
------------------------------------------------------------
hs.notify.show("Hammerspoon Loaded Successfully", "Trust me, this is a good thing!", "")
hs.alert.show("Config loaded", 5.2)
