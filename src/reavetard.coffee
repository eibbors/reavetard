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
reaver = require './reaver'
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

  process.on 'exit', =>
    w.stop()

  # Kill the wash process if we get ctrl+C'ed 
  cli._c.on '^C', =>
    w.stop()
    cli._c.display 'reset'
    process.exit()  

  # Handle access points found by our washing machine
  w.on 'ap', (station) ->
    # Added this extra step to fetch device information available in the DB
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
            cli.washHit station, 'C'
          else 
            stations.inProgress.push station
            cli.washHit station, 'W'
        else
          stations.noHistory.push station
          cli.washHit station, 'N'

  # Handle our washing machine's process ending
  w.on 'exit', ->
    console.log 'wash process ended, beginning review'
    targetReview stations 

  # Output on stderr shows up here until finished
  w.on 'error', ->
    console.error "ERROR: #{arguments}"

  # Let the mayhem begin
  w.start()
  cli.cwrite('magenta', ' Wash scan now in progress, waiting for AP data...\n')
     .cwrite('blue', ' (Press enter when satisfied with results to continue)')
     
  # Start a prompt to capture input (and maybe options later on)
  rtard.prompt '\n', (res) =>
    w.stop()
    console.log res

targetReview = (stations) ->
  # TODO

startReaver = (bssids) ->
  # TODO

# Commander.js stuff to support CLI commands & parse options
# ----------------------------------------------------------------------

rtard # Universal configuration / options
  .version('0.0.1')
  .option('-i, --interface <iface>', 'Choose WLAN interface [mon0]', 'mon0')
  .option('-r, --reaver-path [path]', 'Set path to your reaver.db and session files', '/usr/local/etc/reaver/')
  .option('-d, --rdb-file [filename]', 'Set the filename of your reaver database', 'reaver.db')

rtard # Command definition for `scan`
  .command('scan')
  .description('Initiate an annotated wash survey')
  .action ->
    cli.clear().title().cwrite('blue', ' Scan command chosen. Initializing wash survey...\n')
    washSurvey()

rtard # Command definition for `crack`
  .command('crack <bssids>')
  .description('Initiate reaver cracking session on one or more targets')
  .action(startReaver)

# Parse commmand-line arguments and get on with it already!
rtard.parse process.argv
