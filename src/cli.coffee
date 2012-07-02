# Reavetard - Reaver WPS (+Wash) extension scripts
# cli.coffee :: Module to pimp our command line interface output
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------

commander = require 'commander'
charm = require('charm')(process.stdout)

# Once charm has been loaded, we need to manually implement ^C functionality
exit = ->
  charm.display 'reset'
  process.exit()
charm.on '^C', exit

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
      cwrite.apply null, [a]

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
cdwrite = ->
  if arguments.length >= 2
    charm.display 'reset'
    charm.display arguments[0]
    cwrite.apply null, arguments[1..]


# Constant strings / printable arrays / widgets?
# ----------------------------------------------------------------------

REAVETARD_TITLE = [
  ['reset',  'blue', '                                      eibbors.com/p/reavetard/\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n']
  ['bright',     57, ' -  ▀█▀▀▀▄ ▄▀▀▀▄ ▀▀▀▀▄ █   █ ▄▀▀▀▄ ▄█▄▄  ▀▀▀▀▄ ▀█▀▀▀▄   ▀█   -\n']
  ['bright',     56, ' -   █  ▀  █▀▀▀▀ █▀▀▀█ ▀▄ ▄▀ █▀▀▀▀  █  ▄ █▀▀▀█  █  ▀ ▄▀▀▀█   -\n']
  ['bright',     55, ' -   ▀▀     ▀▀▀▀  ▀▀▀ ▀  ▀    ▀▀▀▀   ▀▀▀  ▀▀▀ ▀ ▀▀    ▀▀▀▀▀  -\n']
  ['reset',  'blue', ' -    ~ Reaver Tools for AP Rotation & Data Management  ~    -\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n\n']
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
  if full then arrwrite REAVETARD_TITLE, false
  else arrwrite REAVETARD_TITLE_S, false
  return @

# Prints the menu options available during an interactive session (soon...)
exports.menu = ->
  arrwrite REAVETARD_MENU
  return @

# Waaahhhh shhhit son, dis here is the real-time survey result 'hit'
# status codes: C='Complete', W='Work In Progress', N='New'
exports.washHit = (station, status) ->
  if station.locked then charm.display('dim') # Takes the focus off of locked stations
  if status is 'C'
    cwrite 57, "[C] rssi:#{station.rssi} bssid:#{station.bssid} ch:#{ch} essid:'#{station.essid}'\n"
    cwrite 57, " |- pin:#{station.session?.pin} key:'#{station.key}'"
  else if status is 'W'
    progress = Number(station.attempts/110).toFixed(2) + '%'
    if station.attempts > 10000 or station.session.phase is 1 then progress += " pin:#{station.session.pin}____"
    cwrite 'magenta', "[W] rssi:#{station.rssi} bssid:#{station.bssid} ch:#{ch} essid:'#{station.essid}'\n"
    cwrite 'magenta', " |- eliminated:#{station.attempts}/11000 ~#{progress} phase:#{station.phase}"
  else if status is 'N' 
    cwrite 'blue', "[C] rssi:#{station.rssi} bssid:#{station.bssid} ch:#{ch} essid:'#{station.essid}'"
  if station.locked then cdwrite 'bright', 'red', ' locked\n' else cwrite 'green', ' unlocked\n'
  cdwrite 'reset', '\n'
  return @

# Helper to print a bold label caption with normal value (or dim ifnot enabled)
exports.label = (ltext, rtext, enabled = true) ->
  charm.display 'bright'
  charm.write ltext
  if enabled then charm.display 'reset'
  else charm.display 'dim'
  charm.write rtext
  return @

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
exports._c = charm