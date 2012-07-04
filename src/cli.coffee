# Reavetard - Reaver WPS (+Wash) extension scripts
# cli.coffee :: Module to pimp our command line interface output
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------

commander = require 'commander'
charm = require('charm')(process.stdout)

# Core helpers used to allow more user-friendly data structures
# ----------------------------------------------------------------------

# Write an array of strings or arrays of the format
# [ FG, BG, TEXT... ], [ FG, TEXT ], or [ TEXT ] 
arrwrite = (arr, cd=false) ->  
  for a in arr
    if Array.isArray a
      if cd then cdwrite.apply null, a
      else cwrite.apply null, a
    else
      if cd then cdwrite.apply null, [a]
      else cwrite.apply null, [a]

# Used to write and color something in one fell swoop
cwrite = ->
  if arguments.length is 1
    charm.write arguments[0]
  else if arguments.length >= 2
    charm.foreground arguments[0]
    if arguments.length >= 3
      charm.background arguments[1]
      charm.write arguments[2..].join()
    else
      charm.write arguments[1]

# Same as above, but assumes an extra 'display' argument at arguments[0]
cdwrite = (disp, args...)->
  charm.display 'reset'
  charm.display disp
  cwrite args...

# Constant strings / printable arrays / widgets?
# ----------------------------------------------------------------------

REAVETARD_TITLE = [
  ['reset',  'blue', '                                      eibbors.com/p/reavetard/\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n']
  ['bright',     57, ' -  ▀█▀▀▀▄ ▄▀▀▀▄ ▀▀▀▀▄ █   █ ▄▀▀▀▄ ▄█▄▄  ▀▀▀▀▄ ▀█▀▀▀▄   ▀█   -\n']
  ['bright',     56, ' -   █  ▀  █▀▀▀▀ █▀▀▀█ ▀▄ ▄▀ █▀▀▀▀  █  ▄ █▀▀▀█  █  ▀ ▄▀▀▀█   -\n']
  ['bright',     55, ' -   ▀▀     ▀▀▀▀  ▀▀▀ ▀  ▀    ▀▀▀▀   ▀▀▀  ▀▀▀ ▀ ▀▀    ▀▀▀▀▀  -\n']
  ['reset',  'blue', ' -    ~ Reaver Tools for AP Rotation & Data Management  ~    -\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n']
  ['reset', '\n']
]

REAVETARD_TITLE_S = [
  ['bright', 57, '  __   _   _  _ _  _  ___ _  __   _   \n']
  ['bright', 56, '  |_| |_|  _| | | |_|  |  _| | | _|   '], ['reset', 'blue', 'CoffeeScript goodies for Reaver-WPS']
  ['bright', 55, '  | \ |__ |_\  V  |__  | |_\ |  |_|_  '], ['reset', 'blue', 'Courtesy of Robbie Saunders (eibbors.com)\n']
  ['magenta', '_________________________________________________________________________________']
] 

REAVETARD_MENU = [ 
  #TODO ME PLEASE!
]

# Exported functions for printing stuff and other such tomfoolery
# ----------------------------------------------------------------------

# Full blown title
exports.title = (full=true)->
  if full then arrwrite REAVETARD_TITLE, true
  else arrwrite REAVETARD_TITLE_S, true
  return @

# Prints the menu options available during an interactive session (soon...)
exports.menu = ->
  arrwrite REAVETARD_MENU, true
  return @

# Waaahhhh shhhit son, dis here is the real-time survey result 'hit'
# status codes: C='Complete', W='Work In Progress', N='New'
exports.washHit = (station, status) ->
  colors = { C:72, W: 'blue', N: 5 }
  c = colors[status]
  if station.locked then c = 'red'
  @label c, 'st', status
  @label c, 'rssi', station.rssi
  @label c, 'bssid', station.bssid 
  @label c, 'ch', station.channel
  @label c, 'essid', station.essid
  if status is 'C'
    @label c, 'pin', station.session?.pin
    @label c, 'key', station.key
    @label c, 'checked', (Number(station.session.ki1) + Number(station.session.ki2))
  else if status is 'W'
    @label c, 'progress', "#{Number(station.attempts/110).toFixed(2)}%"
    @label c, 'phase', station.session.phase
    @label c, 'checks', (Number(station.session.ki1) + Number(station.session.ki2))
    if station.attempts > 10000 or station.session.phase is 1 then @label c, 'pin', "#{station.session.pin}"
  if station.device?
    @label c, 'device', station.device.name
    @label c, 'manuf.', station.device.manufacturer
    @label c, 'model', "#{station.device.model}/#{station.device.number}"
  if station.locked then @label c, '!', 'LOCKED'
  charm.write '\n'  
  return @

# Prints a "label", which is looks like: ltext/RTEXT (caps = bright)
exports.label = (fg, ltext, rtext) ->
  charm.display('reset').foreground(fg).write("#{ltext}/")
  charm.display('bright').foreground(fg).write("#{rtext} ").display('reset')
  return @

# Prints labels for an array of keys that correspond to an object's prop's
exports.labels = (color, keys, obj) ->
  for key in keys
    @label color, key, obj[key]

# *See cwrite above*
exports.cwrite = (args...) ->
  cwrite args...
  return @
# *See cdwrite above*
exports.cdwrite = (args...) ->
  cdwrite args...
  return @

# Don't think this is necessary with erase exposed below
# TODO: Verify and remove or finalize
exports.clear = ->
  charm.erase 'screen'
  charm.position 0,0
  return @

# When extra customization necessary 
exports.write = charm.write
exports.erase = charm.erase
exports.foreground = charm.foreground
exports.background = charm.background
exports.display = charm.display

# Just in case, expose a reference to our charmed stdout stream
exports._c = charm;
