-- PasteBoardExt spoon
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
--- Enable or disable debugging
--- Method
---
--- Parameters:
---  * enable - Boolean indicating whether debugging should be on
---
--- Returns:
---  * Nothing
s.debug = function(self, enable)
  if enable then
    self.log.setLogLevel('debug')
    self.log.d("Debugging enabled")
  else
    self.log.d("Disabling debugging")
    self.log.setLogLevel('info')
  end
end
-- }}}  PasteBoardExt:debug() --

-- PasteBoardExt:bindHotKey() {{{ --
--- PasteBoardExt:bindHotKey(self, table)
--- Method
--- Bind keys to methods.
---
--- Parameters:
---  * table - Table of action to key mappings, e.g.
---   {
---     clean = {{"cmd", "alt"}, "c"},
---     keyStrokes = {{"cmd", "alt"}, "v"},
---     edit = {{"cmd", "alt"}, "e"},
---     openURL = {{"cmd", "alt"}, "o"}
--    }
---
--- Returns:
---  * PasteBoardExt object

s.bindHotKeys = function(self, table)
  for feature,mapping in pairs(table) do
    if feature == "clean" then
       self.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() self:clean() end)
    elseif feature == "keyStrokes" then
       self.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() self:keyStrokes() end)
    elseif feature == "edit" then
       self.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() self:edit() end)
    elseif feature == "openURL" then
       self.hotkey = hs.hotkey.bind(mapping[1], mapping[2],
         function() self:openURL() end)
     else
       log.wf("Unrecognized key binding feature '%s'", feature)
     end
   end
  return self
end
-- }}} PasteBoardExt:bindHotKey() --

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
function s.clean(self)
  local text = nil
  local stext = hs.pasteboard.readStyledText()
  if stext then
    text = stext:getString()
  else
    text = hs.pasteboard.readString()
  end
  if text then
    self.log.d("Cleaning pasteboard.")
    -- Trim non-ascii
    -- Pasteboard strings can have stuff that looks like whitespace
    -- but doesn't match %s
    text = text:gsub("[^\x20-\x7E]", "")
    -- Trim leading and trailing whitespace
    text = text:gsub("[^\x20-\x7E]", ""):gsub("^%s+", ""):gsub("%s+$", "")
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
function s.openURL(self)
  -- XXX This won't return a URL in stylized text
  local url = hs.pasteboard.readURL()
  if url then
    local handler = hs.urlevent.getDefaultHandler(string.match(url, "(%a+):"))
    if hander then
      hs.urlevent.openURLWithBundle(url, handler)
    else
      hs.alert.show("No handler for URL.")
    end
  else
    hs.alert.show("No URL in clipboard")
  end
end
-- }}} PasteBoardExt:openURL() --

return s
-- vim: foldmethod=marker:
