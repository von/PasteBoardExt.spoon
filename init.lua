--- === PasteBoardExt ===
-- Various functions related to the PasteBoard
local s = {}

-- Metadata
s.name="PasteBoardExt"
s.version="0.1"
s.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
s.license="Apache-2.0"
s.homepage="https://github.com/von/PasteBoardExt.spoon"

-- Constants
s.path = hs.spoons.scriptPath()
s.cmd = hs.spoons.resourcePath("/bin/pbedit.sh")

-- Set up logger for spoon
s.log = hs.logger.new("PasteBoardExt")

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
function s:debug(enable)
  if enable then
    s.log.setLogLevel('debug')
    s.log.d("Debugging enabled")
  else
    s.log.d("Disabling debugging")
    s.log.setLogLevel('info')
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

function s:bindHotKeys(table)
  for feature,mapping in pairs(table) do
    if feature == "clean" then
       s.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() s:clean() end)
    elseif feature == "keyStrokes" then
       s.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() s:keyStrokes() end)
    elseif feature == "edit" then
       s.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() s:edit() end)
    elseif feature == "openURL" then
       s.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() s:openURL() end)
     else
       s.log.wf("Unrecognized key binding feature '%s'", feature)
     end
   end
  return s
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
function s:clean()
  local text = nil
  local stext = hs.pasteboard.readStyledText()
  if stext then
    text = stext:getString()
  else
    text = hs.pasteboard.readString()
  end
  if text then
    s.log.d("Cleaning pasteboard.")
    -- Trim non-ascii
    -- Pasteboard strings can have stuff that looks like whitespace
    -- but doesn't match %s
    text = text:gsub("[^\x20-\x7E]", "")
    -- Trim leading and trailing whitespace
    text = text:gsub("[^\x20-\x7E]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if not hs.pasteboard.setContents(text) then
      s.log.w("Failed to set pasteboard contents.")
    end
  else
    s.log.d("Pasteboard empty.")
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
function s.keyStrokes(self)
  local text = hs.pasteboard.getContents()
  hs.eventtap.keyStrokes(text)
end

-- }}} PasteBoardExt:keyStrokes() --

-- PasteBoardExt:edit() {{{ --
--- PasteBoardExt.edit()
--- Method
--- Edit the PasteBuffer.
--- Currently uses MacVim and is specific to the Mac.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function s.edit(self)
  -- Save focused widow so we can restore it
  local focusedWindow = nil
  local frontApp = hs.application.frontmostApplication()
  if frontApp ~= nil then
    focusedWindow = frontApp:focusedWindow()
  end
  local callback = function(exitCode, stdOut, stdErr)
    self.log.df("Restoring %s", focusedWindow:title())
    focusedWindow:application():activate()
    focusedWindow:focus()
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
