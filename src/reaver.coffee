# Reavetard - Reaver WPS (+Wash) extension scripts
# reaver.coffee :: Module to spawn reaver processes and provide basic output
#   parsing via status update events
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
events = require 'events'
{spawn, exec} = require 'child_process'

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
  verbose:        ['-vv', '--verbose', 'Display non-critical warnings (-vv for more)', false]
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

### Child process wrapper for spawned reaver processes ###
class Reaver extends events.EventEmitter

  constructor: (options) ->
    for own key, value of options
      @[key] = value
    @interface ?= 'mon0'
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
    @metrics = 
      consecutiveFailures: 0
      totalFailures: 0
      totalChecked: 0
      timeToCrack: null
      secondsPerPin: null

  # Setting a duration will switch to exec vs. real time parsing (spawn)
  start: (args) =>
    # create an arguments array, if not provided by caller
    if not args?
      args = []
      for key, value of REAVER_ARGS when @[key]?
        [flag, option, desc, inclVal] = value
        if @[key] or inclVal then args.push flag
        if inclVal then args.push @[key]
    console.log args
    # kill the existing process, then spawn a new one and bind to the data event
    @stop()
    @proc = spawn 'reaver', args
    @proc.stdout.on 'data', @process
    @proc.stderr.on 'data', @process

  stop: () ->
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
          if @status.pin isnt res[1]
            @metrics.totalChecked++
            @metrics.consecutiveFailures = 0
            if @status.phase is 0 and @status.pin[0..3] is res[1][0..3]
              @status.phase = 1
              @emit 'completed', 1, { pin: res[1][0..3] }
            @status.pin = res[1]
          @status.sequenceDepth = 0
        when 'sending', 'received'
          if REAVER_PACKET_SEQ[res[1]] > @status.sequenceDepth
            @status.sequenceDepth = REAVER_PACKET_SEQ[res[1]]
        when 'timedOut', 'wpsFailure'
          @metrics.consecutiveFailures++
          @metrics.totalFailures++
        when 'rateLimit', 'associateFailure'
          @status.associated = false 
          @status.locked = (matched is 'rateLimit')
          @status.sequenceDepth = -1
        when 'consecutiveFailures'
          @metrics.consecutiveFailures 
        when 'progress'
          @metrics.secondsPerPin = res[4] ? null
        when 'crackedPSK'
          @emit 'completed', 2, { psk: res[1] }
        when 'crackedPIN'
          @emit 'completed', 2, { pin: res[1] }
        when 'crackedTime'
          @status.phase = 2
          @metrics.timeToCrack = res[1..2].join(' ')
        when 'crackedSSID'
          @emit 'completed', 2, { ssid: res[1] }
      @emit 'status', matched, @status, res


module.exports = Reaver