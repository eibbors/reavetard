# Reavetard - Reaver WPS (+Wash) extension scripts
# db.coffee :: Swankified access to reaver.db and .wpc session files
#   Currently depends on sqlite3 bindings which may be difficult to install
#   on Backtrack (I had to make some manual changes to get the plugin built properly)
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencices
# -------------------------
sqlite3 = require('sqlite3').verbose()
fs = require 'fs'
Pins = require './pins'

# Wrapper class for dealing with Reaver's data storage
class ReaverData
  # Requires the user's local reaver data path and db filename
  constructor: (@rvrPath = '/usr/local/etc/reaver/', @dbFile = 'reaver.db') ->
    # Make sure we have ourselves a trailing slash on the reaver path
    @rvrPath += '/' unless @rvrPath[-1..] is '/'
    # Create a new database instance
    @db = new sqlite3.Database "#{@rvrPath}#{@dbFile}"

  # Super simple wrappers for querying Reaver's 3 database tables
  getHistory: (cb) ->
    @db.all "SELECT * FROM history ORDER BY timestamp DESC", cb
  getSurvey: (cb) ->
    @db.all "SELECT * FROM survey ", cb
  getStatus: (cb) ->
    @db.all "SELECT * FROM status", cb

  # Query history/survey data for an AP by bssid
  checkHistory: (bssid, cb) ->
    @db.all "SELECT * FROM history WHERE bssid = '#{bssid}'", cb

  # Loads relevant session data, given bssid or filename (if non-standard)
  loadSession: (bssid, filename) =>
    if bssid? and not filename?
      filename = "#{@rvrPath}#{bssid}.wpc".replace /:/g, ''
    try
      session = fs.readFileSync filename, 'utf8'    
      session = session.split("\n")   
    catch error
      session = [0, 0, 0, []]
    # The last row is a blank line, first 3 aren't keys, so exclude 0-2 and -1:
    pset = new Pins(session[3...-1])
    ki1 = session[0]
    ki2 = session[1]
    phase = session[2]
    switch phase
      when '2'
        pin = pset.get(ki1,ki2)
      when '1'
        pin = pset.keyAt(1,ki1)
      when '0'
        pin = null
    { phase, pin, Pins: pset, ki1, ki2 }

  # Used to write session files, useful when you accidentally enter in an incorrect
  # PIN or want to customie the pin order (randomize ,reverse, etc)
  writeSession: (bssid, phase=0, ki1=0, ki2=0, pins, filename) ->
    filename ?= "#{@rvrPath}#{bssid}.wpc".replace /:/g, ''
    pins ?= new Pins()
    if Array.isArray(pins) then pins = new Pins(pins)
    else if typeof(pins) is 'string' then pins = new Pins(pins.split('\n'))
    output = "#{ki1}\n#{ki2}\n#{phase}\n#{pins.buildEnum().join('\n')}"
    fs.writeFileSync filename, output, 'utf8'

module.exports = ReaverData