# Reavetard - Reaver WPS (+Wash) extension scripts
# wash.coffee :: Module that spawns wash child processes and parses any AP data
#   that they spit out 
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
events = require 'events'
{spawn, exec} = require 'child_process'

# Arguments supported by the wash command in the format:
# key: [shortFlag, fullFlag, description, includesValue]
WASH_ARGS =
  interface: ['-i', '--interface=<iface>', 'Interface to capture packets on', true]
  file:      ['-f', '--file [FILE1 FILE2 FILE3 ...]', 'Read packets from capture files', true]
  channel:   ['-c', '--channel=<num>', 'Channel to listen on [auto]', true]
  outFile:   ['-o', '--out-file=<file>', 'Write data to file', true]
  probes:    ['-n', '--probes=<num>', 'Maximum number of probes to send to each AP in scan mode [15]', true]
  daemonize: ['-D', '--daemonize', 'Daemonize wash', false]
  ignoreFCS: ['-C', '--ignore-fcs', 'Ignore frame checksum errors', false]
  use5ghz:   ['-5', '--5ghz', 'Use 5GHz 802.11 channels', false]
  scan:      ['-s', '--scan', 'Use scan mode', false]
  survey:    ['-u', '--survey', 'Use survey mode [default]', false]
  help:      ['-h', '--help', 'Show help', false]

### Child process wrapper for spawned wash processes ###
class Wash extends events.EventEmitter

  constructor: (options) ->
    for own key, value of options
      @[key] = value
    @interface ?= 'mon0'
    @scan ?= true
    @proc = null

  # Setting a duration will switch to exec vs. real time parsing (spawn)
  start: (args, duration=0) ->
    # create an arguments array, if not provided by caller
    if not args?
      args = []
      for key, value of WASH_ARGS when @[key]?
        [flag, option, desc, inclVal] = value
        if @[key] or inclVal then args.push flag
        if inclVal then args.push @[key]
    # kill the existing process, then spawn a new one and bind to the data event
    @stop()
    if duration > 0
      @proc = undefined
      exec 'wash', args, (output) =>
        for line in output.split('\n')
          @process line
    else 
      @proc = spawn 'wash', args
      @proc.stdout.on 'data', @process
      @proc.stderr.on 'data', @process

  stop: () ->
    if @proc
      @proc.kill()
      @emit 'exit', true

  # parse and emit any discovered stations
  process: (data) =>
    ap = ///
          (\w\w(:\w\w)+)\s+ # bssid
          (\d+)\s+ # channel
          (-\d+)\s+ #rssi
          (\d\.\d)\s+ # wps version 
          (Yes|No)\s+ # wps locked?
          (.*) # essid 
        ///.exec(data.toString())
    if ap then @emit 'ap',
      bssid:   ap[1]
      channel: ap[3] 
      rssi:    ap[4]
      version: ap[5]
      locked: (ap[6] is 'Yes')
      essid:   ap[7] 

module.exports = Wash
