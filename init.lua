--- === PasteBoardExt ===
--- Various functions related to the PasteBoard
local PasteBoardExt = {}

-- Metadata {{{ --
PasteBoardExt.name="PasteBoardExt"
PasteBoardExt.version="0.2"
PasteBoardExt.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
PasteBoardExt.license="Apache-2.0"
PasteBoardExt.homepage="https://github.com/von/PasteBoardExt.spoon"
-- }}} Metadata --

-- PasteBoardExt:init() {{{ --
--- PasteBoardExt:init()
--- Method
--- Initializes a PasteBoardExt
--- When a user calls hs.loadSpoon(), Hammerspoon will load and execute init.lua
--- from the relevant s.
--- Do generally not perform any work, map any hotkeys, start any timers/watchers/etc.
--- in the main scope of your init.lua. Instead, it should simply prepare an object
--- with methods to be used later, then return the object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PasteBoardExt object
function PasteBoardExt:init()
  self.log = hs.logger.new("PasteBoardExt")
  self.path = hs.spoons.scriptPath()
  self.cmd = hs.spoons.resourcePath("/bin/pbedit.sh")
  return self
end
-- }}} PasteBoardExt:init() --

-- PasteBoardExt:debug() {{{ --
--- PasteBoardExt:debug(enable)
--- Method
--- Enable or disable debugging
---
--- Parameters:
---  * enable - Boolean indicating whether debugging should be on
---
--- Returns:
---  * Nothing
function PasteBoardExt:debug(enable)
  if enable then
    self.log.setLogLevel('debug')
    self.log.d("Debugging enabled")
  else
    self.log.d("Disabling debugging")
    self.log.setLogLevel('info')
  end
end
-- }}} PasteBoardExt:debug() --

-- PasteBoardExt:bindHotKeys() {{{ --
--- PasteBoardExt:bindHotKeys(table)
--- Method
--- Bind keys to methods. Valid keys for provided table are "clean", "keystrokes",
--- "edit", "openURL"
---
--- Parameters:
---  * table - Table of action to key mappings.
---
--- Returns:
---  * PasteBoardExt object

function PasteBoardExt:bindHotKeys(table)
  for feature,mapping in pairs(table) do
    if feature == "clean" then
       hs.hotkey.bind(mapping[1], mapping[2], function() self:clean() end)
    elseif feature == "keyStrokes" then
       hs.hotkey.bind(mapping[1], mapping[2], function() self:keyStrokes() end)
    elseif feature == "edit" then
       hs.hotkey.bind(mapping[1], mapping[2], function() self:edit() end)
    elseif feature == "openURL" then
       hs.hotkey.bind(mapping[1], mapping[2], function() self:openURL() end)
     else
       s.log.wf("Unrecognized key binding feature '%s'", feature)
     end
   end
  return self
end
-- }}} PasteBoardExt:bindHotKeys() --

-- PasteBoardExt:clean() {{{ --
--- PasteBoardExt:clean()
--- Method
--- Clean up the pasteboard:
---   * Convert stylized text to plain text
---   * Remove leading and training whitepace
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function PasteBoardExt:clean()
  local text = hs.pasteboard.readString()
  if not text then
    local stext = hs.pasteboard.readStyledText()
    if stext then
      log.d("Converting from StyledText")
      text = stext:getString()
    end
  end
  if text then
    self.log.d("Cleaning pasteboard.")
    -- Trim leading and trailing whitespace
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if not hs.pasteboard.setContents(text) then
      self.log.w("Failed to set pasteboard contents.")
    end
  else
    self.log.d("Pasteboard empty.")
  end
end
-- }}} PasteBoardExt:clean() --

-- PasteBoardExt:keyStrokes() {{{ --
--- PasteBoardExt:keyStrokes()
--- Method
--- Paste PasteBoard using hs.eventtap,keyStrokes()
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function PasteBoardExt:keyStrokes()
  local text = hs.pasteboard.getContents()
  hs.eventtap.keyStrokes(text)
end

-- }}} PasteBoardExt:keyStrokes() --

-- PasteBoardExt:edit() {{{ --
--- PasteBoardExt:edit()
--- Method
--- Edit the PasteBuffer.
--- Currently uses MacVim and is specific to the Mac.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function PasteBoardExt:edit()
  -- Save focused widow so we can restore it
  local focusedWindow = nil
  local frontApp = hs.application.frontmostApplication()
  if frontApp ~= nil then
    focusedWindow = frontApp:focusedWindow()
  end
  local callback = function(exitCode, stdOut, stdErr)
    if frontApp then
      self.log.df("Reactivating %s", frontApp:title())
      frontApp:activate()
      if focusedWindow then
        self.log.df("Focusing %s", focusedWindow:title())
        focusedWindow:focus()
      end
    end
    if exitCode ~= 0 then
      self.log.wf("Edit failed: %s", stdErr)
    end
  end

  local t = hs.task.new(self.cmd, callback)
  if not t:start() then
    self.log.wf("Failed to start task (%s)", self.cmd)
  end
end
-- }}} PasteBoardExt:edit() --

-- PasteBoardExt:openURL() {{{ --
--- PasteBoardExt:openURL()
--- Method
--- Open URL in clipboard
---
--- Parameters:
--- * None
---
--- Returns:
--- * True on success, false on failure
function PasteBoardExt:openURL()
  -- We don't use hs.pareboard.readURL() here because it is very fragile and
  -- breaks if there is any unusal characters in the pasteboard, which I'm
  -- seeing copying links from Chrome do frequently.
  local url = hs.pasteboard.readString()
  -- local url = hs.pasteboard.readURL()
  if not url then
    hs.alert.show("Clipboard empty")
    return false
  end
  -- Remove any non-ascii characters
  url = url:gsub("[^\x20-\x7E]", "")
  -- Trim leading and trailing whitespace
  url = url:gsub("[^\x20-\x7E]", ""):gsub("^%s+", ""):gsub("%s+$", "")
  local protocol = string.match(url, "(%a+):")
  if not protocol then
    hs.alert("Not recognizable URL in clipboard")
    self.log.df("Not recognizable URL in clipboard: %s", url)
    return false
  end
  local handler = hs.urlevent.getDefaultHandler(protocol)
  if not handler then
    hs.alert("Not handler for protocol " .. protocol)
    self.log.df("No hander for protocol (%s): %s", protocol, url)
    return false
  end
  hs.urlevent.openURLWithBundle(url, handler)
end
-- }}} PasteBoardExt:openURL() --

return PasteBoardExt
-- vim: foldmethod=marker:
