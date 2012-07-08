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

# `Command` handlers and their misc. helper functions
# ----------------------------------------------------------------------

washSurvey = (scan = true) =>
  stations = # Used to categorize results for later review
    complete:   []
    inProgress: []
    noHistory:  []
  rdb = new db()
  w = new wash { interface: 'mon0', scan, ignoreFCS: true }

  # Clean wash up in case we missed another chance to stop it
  # These processes go absolutely bonkers with your resources once there's
  # around three or more of the bastards left open. hah
  process.on 'exit', =>
    w.stop()

  # After messing around with different options, this seemed simple & intuitive enough
  cli._c.foreground(250)
  rtard.prompt ' *** Press enter to move on to next step ***', =>
    w.stop()
    process.nextTick -> targetReview.apply(null, [stations])

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

  # Handle our washing machine's spin cycle ending early (removed for now)
  #w.on 'exit', ->
    #console.log 'Wash process has ended. Press enter to continue.'

  # Hopefully you won't be seeing any of these!
  w.on 'error', ->
    console.error "ERROR: #{arguments}"

  # Let the mayhem begin
  w.start()
  cli.cwrite('magenta', ' Wash scan has been started, now waiting for AP data...\n\n')

rdbQuery = () =>
  stations = # Used to categorize results for later review
    complete:   []
    inProgress: []
    noHistory:  []
  rdb = new db()

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
        process.nextTick -> targetReview.apply(null, [stations])


# Present ansi-formatted tables containing scan/query results, from which user can select from
targetReview = (stations, reprompt=false) ->
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
    actionPrompt = =>
      rtard.prompt '\n Please enter one of the letters in ()\'s, or entire title, of your desired action: ', (choice) =>
        switch choice
          when 'a', 'attack'
            process.nextTick -> startNewAttack.apply(null, [selected]) 
          when 'j', 'json'
            rtard.confirm 'Would you like to include session file key data? Doing so may add 11,000 keys to each station\'s output. (Y/N):', (showPins) ->
              if not showPins
                for s in selected when s.session?
                  s.session.Pins = 'removed'
              console.log JSON.stringify selected
              process.exit()
          when 'u', 'usage'
            for s in selected
              console.log "reaver -i mon0 -b #{s.bssid} #{if s.channel then '-c ' + s.channel} -vv -a -N -S"
            process.exit()
          when 'x', 'exit'
            console.log 'goodbye.'
            process.exit()
          else
            console.log 'You didn\'t enter one of the available letters/words. Try again.\n'
            process.nextTick actprompt
    actionPrompt()

startNewAttack = (selected) ->
  atkQueue = new ReaverQueueManager(selected, rtard.interface)
  atkQueue.on 'stopped', =>
    if atkQueue.priority.length >= 1 or atkQueue.secondary.length >= 1
      process.nextTick atkQueue.start
    else
      attackReview atkQueue
  atkQueue.start()
  process.on 'exit', =>
    atkQueue.stop('killed')
  attackPrompt = =>
    cli._c.foreground('blue')
    rtard.prompt ' You may enter a command at any moment: ', (cmd) ->
      switch cmd
        when 'n', 'next'
          atkQueue.stop('skipped')
          process.nextTick attackPrompt
        when 'x', 'exit'
          atkQueue.stop('killed')
          process.exit()
        else
          process.nextTick attackPrompt
  attackPrompt()

# Runs on an interval, displaying extra updates and checking for errors
attackProgress = (queue) ->


attackReview = (queue) ->
  console.log queue.finished

# Commander.js stuff to support CLI commands & parse options
# ----------------------------------------------------------------------

rtard # Universal configuration / options
  .version('0.0.6')
  .option('-i, --interface <iface>', 'Choose WLAN interface [mon0]', 'mon0')
  .option('-r, --reaver-path [path]', 'Set path to your reaver.db and session files', '/usr/local/etc/reaver/')
  .option('-d, --rdb-file [filename]', 'Set the filename of your reaver database', 'reaver.db')

rtard # Command definition for `scan`
  .command('scan')
  .description('Spawn an annotated wash survey to generate targets')
  .action ->
    cli.clear().title().cwrite('blue', ' Scan command chosen. Initializing wash survey...\n')
    washSurvey()

rtard # Command definition for `rdbq` (reaver database query)
  .command('rdbq')
  .description('Generate targets from existing database entries and session files')
  .action ->
    cli.clear().title().cwrite('blue', ' Reaver DB Query command chosen, Initializing query... \n\n')
    rdbQuery()

rtard # Command definition for `crack`
  .command('crack <bssids>')   
  .description('Initiate reaver cracking session on one or more targets')
  .action(startNewAttack)

# Parse commmand-line arguments and get on with it already!
rtard.parse process.argv