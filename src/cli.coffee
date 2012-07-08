# Reavetard - Reaver WPS (+Wash) extension scripts
# cli.coffee :: Module to pimp our command line interface output
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
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
      charm.write arguments[2]
    else
      charm.write arguments[1]

# Same as above, but assumes an extra 'display' argument at arguments[0]
cdwrite = (disp, fg, bg, str) ->
  charm.display 'reset'
  charm.display disp
  args = []
  if fg? then args.push fg
  if bg? then args.push bg
  if str? then args.push str
  cwrite.apply null, args

# Constant strings / printable arrays / widgets?
# ----------------------------------------------------------------------

REAVETARD_TITLE = [
  ['reset',  'blue', '                                      eibbors.com/p/reavetard/\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n']
  ['bright',     57, ' -  ▀█▀▀▀▄ ▄▀▀▀▄ ▀▀▀▀▄ █   █ ▄▀▀▀▄ ▄█▄▄  ▀▀▀▀▄ ▀█▀▀▀▄   ▀█   -\n']
  ['bright',     56, ' -   █  ▀  █▀▀▀▀ █▀▀▀█ ▀▄ ▄▀ █▀▀▀▀  █  ▄ █▀▀▀█  █  ▀ ▄▀▀▀█   -\n']
  ['bright',     55, ' -   ▀▀     ▀▀▀▀  ▀▀▀ ▀  ▀    ▀▀▀▀   ▀▀▀  ▀▀▀ ▀ ▀▀    ▀▀▀▀▀  -\n']
  ['reset',  'blue', ' -  Coffee-powered enhancements for WPS PIN Cracker, Reaver  -\n']
  ['dim', 'magenta', ' -------------------------------------------------------------\n']
  ['reset', '\n']
]

REAVETARD_TITLE_S = [
  ['bright', 57, '  __   _   _  _ _  _  ___ _  __   _   \n']
  ['bright', 56, '  |_| |_|  _| | | |_|  |  _| | | _|   '], ['reset', 'blue', 'CoffeeScript goodies for Reaver-WPS\n']
  ['bright', 55, '  | \\ |__ |_\\  V  |__  | |_\\ |  |_|_  '], ['reset', 'blue', 'Courtesy of Robbie Saunders (eibbors.com)\n\n']
] 

REVIEW_SELECTORS = [
  ['bright', 250, '\n Special Selectors: \n']
  [ 'reset', 240, ' ---------------------------------------------------------------------------------']
  ['bright', 'white', '\n 0 /']
  [ 'reset', 'white', ' Select all']  
  ['bright', 'black', ', ']
  ['bright', 'green', ' -1 /']
  [ 'reset', 'green', ' Cracked targets']
  ['bright', 'black', ', ']
  ['bright', 'blue', '-2 /']
  [ 'reset', 'blue', ' Targets in progress']
  ['bright', 'black', ', ']
  ['bright', 5, '-3 /']
  [ 'reset', 5, ' New targets\n']
  ['reset', 5, 'Note: separate multiple selections with any non-digit character, except for `-`\n']
]

# TODO: substitute the sloppy hardcoded colors with a reference to one of these (perhaps move to config file)
STATION_COLORS = exports.STATION_COLORS = { C:'green', W: 'blue', N: 5 }

# Menu of post-selection target actions
REAVETARD_TARGET_ACTIONS = [ 
   ['bright', 'magenta', '   (a)ttack : '], ['reset', 'magenta', 'Queue the station(s) for attack and begin cracking\n']
   ['bright', 'magenta', '   (d)elete : '], ['reset', 'magenta', 'Delete their database entries and/or session files\n']
   ['bright', 'magenta', '   (e)xport : '], ['reset', 'magenta', 'Export reaver.db and session file(s) to a new location\n'] 
   ['bright', 'magenta', '     (j)son : '], ['reset', 'magenta', 'Output JSON object(s) containing all available target data\n']
   ['bright', 'magenta', ' (s)essions : '], ['reset', 'magenta', 'Create and/or Customize their session files\n']
   ['bright', 'magenta', '    (u)sage : '], ['reset', 'magenta', 'Print reavetard\'s best guess @ proper reaver arguments (usage)\n']
   ['bright', 'magenta', '     e(x)it : '], ['reset', 'magenta', 'End process without doing anything else\n']
]

# Exported functions for printing stuff and other such tomfoolery
# ----------------------------------------------------------------------

# Full blown title
exports.title = (full=true)->
  if full then arrwrite REAVETARD_TITLE, true
  else arrwrite REAVETARD_TITLE_S, true
  return @

# Prints the actions available once one or more stations have been selected post-scan/query/passing
exports.targetActions = ->
  arrwrite REAVETARD_TARGET_ACTIONS, true
  return @

# Print the key for the extra selector #'s
exports.reviewSelectors = () ->
  arrwrite REVIEW_SELECTORS, true
  return @

# TODO: Clean this mess up and keep things DRYer
# Used to print the snazzy table headers, dividers, and footers, including variable sizes for their essid/psk
exports.tableFrame = (type, maxessid, maxpsk, foot=false, line=false) =>
  if line then char = '-' else char = '='
  esect = new Array(maxessid + 1).join(char)
  psect = new Array(maxpsk + 1).join(char)
  if type is 'C'
    if line then return charm.write("\n |----+------+----+---+-------------------+#{esect}--+-------+----------+--#{psect}|\n")
    if foot then return charm.display('bright').write("\n \\=================================================================#{psect}#{esect}/\n\n")
    charm.display('reset').foreground('green').display('bright')
    charm.write(" /=================================================================#{psect}#{esect}\\\n")
    charm.write(" | ## | RSSI | Ch | L | BSSID             |")
    @tableCell 'green', 'bright', 'ESSID', maxessid
    charm.display('bright').write(' Att.  | PIN      |')
    @tableCell 'green', 'bright', 'WPA PSK', maxpsk
    charm.display('bright').write("\n |=================================================================#{psect}#{esect}|\n")
  else if type is 'W'
    if line then return charm.write("\n |----+------+----+---+-------------------+#{esect}--+-------+---------------+------|\n")
    if foot then return charm.display('bright').write("\n \\==========================================================================#{esect}/\n\n")
    charm.display('reset').foreground('blue').display('bright')
    charm.write(" /==========================================================================#{esect}\\\n")
    charm.write(" | ## | RSSI | Ch | L | BSSID             |")
    @tableCell 'blue', 'bright', 'ESSID', maxessid
    charm.display('bright').write(' Att.  | Progress      | PIN  |\n')
    charm.write(" |==========================================================================#{esect}|\n")
  else if type is 'N'
    if line then return charm.write("\n |----+------+----+---+-------------------+#{esect}--|\n")
    if foot then return charm.display('bright').write("\n \\===========================================#{esect}/\n")
    charm.display('reset').foreground(5).display('bright')
    charm.display('bright').write(" /===========================================#{esect}\\\n")
    charm.write(" | ## | RSSI | Ch | L | BSSID             |")
    @tableCell 5, 'bright', 'ESSID', maxessid
    charm.display('bright').write("\n |===========================================#{esect}|\n")
  return @

# prints a table cell + closing divider, ie: " 12341234 |"
# returns a copy of itself with the same color/display for convenience
exports.tableCell = (color, disp, value, size) ->
  if value is 'undefined' or value is undefined then value = ' '
  charm.display('reset').display(disp).foreground(color)
  if value.length > size then charm.write(" #{value[0..(size-1)]} ")
  else 
    charm.write(" #{value} ")
    if value.length < size
      # prints spaces, padding the cell to the desired size
      charm.write((new Array(size+1-value.length)).join(' '))
  charm.display('reset').foreground(color).write('|')
  return fn = (v, s) =>
    exports.tableCell.apply null, [color, disp, v, s]

# TODO: This goloiath could benefit from some pampering, but seems to do the trick
# Print up to 3 tables based on the provided station categories, each station is 
# given a unique value for their 'tableIndex' property as they're sequentially printed.
# These are later used to select/filter out the specific targets desired by the user.
exports.targetReviewTable = (stations) ->
  maxessid = 0
  maxpsk = 0
  for key,val of stations
    for s in val
      if s.essid?.length > maxessid then maxessid = s.essid.length
      if s.key?.length > maxpsk then maxpsk = s.key.length
  beginrow = (color, st) =>
    charm.write(' |')
    @tableCell(color, 'reset', "#{st.tableIndex}", 2)("#{st.rssi}", 4)("#{st.channel}", 2)
    if st.locked then charm.foreground('red').display('bright').write(' Y ').display('reset').foreground(color).write('|')
    else @tableCell color, 'reset', 'n', 1
    @tableCell(color, 'reset', "#{st.bssid}", 17)("#{st.essid}", maxessid)
  @title false # print short title ascii art
  indexed = []
  if stations.complete?.length >= 1
    @tableFrame 'C', maxessid, maxpsk
    stations.complete.sort (a,b) -> 
      if a.rssi > b.rssi then 1 else -1
    for s in stations.complete
      s.tableIndex = indexed.length + 1
      indexed.push s 
      if indexed.length > 1 then @tableFrame 'C', maxessid, maxpsk, false,true
      beginrow 'green', s
      @tableCell('green', 'reset', "#{(Number(s.session.ki1) + Number(s.session.ki2))}", 5)("#{s.session.pin}", 8)("#{s.key}", maxpsk)
    @tableFrame 'C', maxessid, maxpsk, true
  if stations.inProgress?.length >= 1
    @tableFrame 'W', maxessid, maxpsk
    isfirst = true 
    stations.inProgress.sort (a,b) -> 
      if a.attempts < b.attempts then 1 else -1
    for s in stations.inProgress
      s.tableIndex = indexed.length + 1
      indexed.push s 
      if isfirst then isfirst = false
      else @tableFrame 'W', maxessid, maxpsk, false, true
      perc = Math.round(Number(s.attempts/110))
      beginrow 'blue', s
      @tableCell('blue', 'reset', "#{s.attempts}", 5)("#{(new Array(Math.round(perc/10)+1)).join('█')} #{perc}%", 13)(s.session.pin ? ' ', 4)
    @tableFrame 'W', maxessid, maxpsk, true
  if stations.noHistory?.length >= 1
    @tableFrame 'N', maxessid, maxpsk
    isfirst = true
    stations.noHistory.sort (a,b) ->  
      if a.rssi > b.rssi then 1 else -1
    for s in stations.noHistory
      s.tableIndex = indexed.length + 1
      indexed.push s 
      if isfirst then isfirst = false
      else @tableFrame 'N', maxessid, maxpsk, false,true
      beginrow 5, s
    @tableFrame 'N', maxessid, maxpsk, true
  return indexed

# Waaahhhh shhhit son, dis here is the real-time survey result 'hit'
# status codes: C='Complete', W='Work In Progress', N='New'
exports.washHit = (station, status, isdbq = false) ->
  c = STATION_COLORS[status]
  if station.locked then c = 'red'
  @label c, ' st', status
  if not isdbq or station.rssi? then @label c, 'rssi', station.rssi
  @label c, 'bssid', station.bssid 
  if not isdbq then @label c, 'ch', station.channel
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

