(function() {
  var REAVER_ARGS, REAVER_PACKET_SEQ, REAVER_PATTERNS, Reaver, events, exec, spawn, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  events = require('events');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  REAVER_ARGS = {
    interface: ['-i', '--interface', 'Name of the monitor-mode interface to use', true],
    bssid: ['-b', '--bssid', 'BSSID of the target AP', true],
    mac: ['-m', '--mac', 'MAC of the host system', true],
    essid: ['-e', '--essid', 'ESSID of the target AP', true],
    channel: ['-c', '--channel', 'Set the 802.11 channel for the interface (implies -f)', true],
    outFile: ['-o', '--out-file', 'Send output to a log file [stdout]', true],
    session: ['-s', '--session', 'Restore a previous session file', true],
    exec: ['-C', '--exec', 'Execute the supplied command upon successful pin recovery', true],
    daemonize: ['-D', '--daemonize', 'Daemonize reaver', false],
    auto: ['-a', '--auto', 'Auto detect the best advanced options for the target AP', false],
    fixed: ['-f', '--fixed', 'Disable channel hopping', false],
    use5ghz: ['-5', '--5ghz', 'Use 5GHz 802.11 channels', false],
    verbose: ['-vv', '--verbose', 'Display non-critical warnings (-vv for more)', false],
    quiet: ['-q', '--quiet', 'Only display critical messages', false],
    help: ['-h', '--help', 'Show help', false],
    pin: ['-p', '--pin', 'Use the specified 4 or 8 digit WPS pin', true],
    delay: ['-d', '--delay', 'Set the delay between pin attempts [1]', true],
    lockDelay: ['-l', '--lock-delay', 'Set the time to wait if the AP locks WPS pin attempts [60]', true],
    maxAttempts: ['-g', '--max-attempts', 'Quit after num pin attempts', true],
    failWait: ['-x', '--fail-wait', 'Set the time to sleep after 10 unexpected failures [0]', true],
    recurringDelay: ['-r', '--recurring-delay', 'Sleep for y seconds every x pin attempts', true],
    timeout: ['-t', '--timeout', 'Set the receive timeout period [5]', true],
    m57Timeout: ['-T', '--m57-timeout', 'Set the M5/M7 timeout period [0.20]', true],
    noAssociate: ['-A', '--no-associate', 'Do not associate with the AP (association must be done by another application)', false],
    noNacks: ['-N', '--no-nacks', 'Do not send NACK messages when out of order packets are received', false],
    dhSmall: ['-S', '--dh-small', 'Use small DH keys to improve crack speed', false],
    ignoreLocks: ['-L', '--ignore-locks', 'Ignore locked state reported by the target AP', false],
    eapTerminate: ['-E', '--eap-terminate', 'Terminate each WPS session with an EAP FAIL packet', false],
    nack: ['-n', '--nack', 'Target AP always sends a NACK [Auto]', false],
    win7: ['-w', '--win7', 'Mimic a Windows 7 registrar [False]', false]
  };

  REAVER_PATTERNS = {
    sending: /Sending (.*)/,
    received: /Received (.*)/,
    tryingPin: /Trying pin (\d+)/,
    timedOut: /WARNING: Receive timeout occurred/,
    wpsFailure: /WPS transaction failed \(code: (\w+)\)/,
    newChannel: /Switching (\w+) to channel (\d+)/,
    waitingBeacon: /Waiting for beacon from (\S+)/,
    associated: /Associated with (\S+)/,
    rateLimit: /WARNING: Detected AP rate limiting, waiting (\d+) seconds before re-checking/,
    associateFailure: /WARNING: Failed to associate with (\S+) \(ESSID: (.*)\)/,
    consecutiveFailures: /WARNING: (\d+) failed connections in a row/,
    progress: /(\S+)% complete @ (\S+) (\S+) \((\d+) seconds\/pin\)/,
    crackedTime: /Pin cracked in (\d+) (\w+)/,
    crackedPIN: /WPS PIN: '(\d+)'/,
    crackedPSK: /WPA PSK: '(.*)'/,
    crackedSSID: /AP SSID: '(.*)'/,
    version: /Reaver v(\S+) WiFi Protected Setup Attack Tool/
  };

  REAVER_PACKET_SEQ = {
    'EAPOL START request': 1,
    'identity request': 2,
    'identity response': 3,
    'M1 message': 4,
    'M2 message': 5,
    'M3 message': 6,
    'M4 message': 7,
    'M5 message': 8,
    'M6 message': 9,
    'M7 message': 10,
    'WSC NACK': 0
  };

  /* Child process wrapper for spawned reaver processes
  */

  Reaver = (function() {

    __extends(Reaver, events.EventEmitter);

    function Reaver(options) {
      this.process = __bind(this.process, this);
      this.start = __bind(this.start, this);
      var key, value, _ref2, _ref3;
      for (key in options) {
        if (!__hasProp.call(options, key)) continue;
        value = options[key];
        this[key] = value;
      }
      if ((_ref2 = this.interface) == null) this.interface = 'mon0';
      if ((_ref3 = this.bssid) == null) this.bssid = null;
      this.proc = null;
      this.status = {
        foundBeacon: false,
        associated: false,
        locked: false,
        channel: 0,
        pin: null,
        phase: 0,
        sequenceDepth: -1
      };
      this.metrics = {
        consecutiveFailures: 0,
        totalFailures: 0,
        totalChecked: 0,
        timeToCrack: null,
        secondsPerPin: null
      };
    }

    Reaver.prototype.start = function(args) {
      var desc, flag, inclVal, key, option, value;
      if (!(args != null)) {
        args = [];
        for (key in REAVER_ARGS) {
          value = REAVER_ARGS[key];
          if (!(this[key] != null)) continue;
          flag = value[0], option = value[1], desc = value[2], inclVal = value[3];
          if (this[key] || inclVal) args.push(flag);
          if (inclVal) args.push(this[key]);
        }
      }
      console.log(args);
      this.stop();
      this.proc = spawn('reaver', args);
      this.proc.stdout.on('data', this.process);
      return this.proc.stderr.on('data', this.process);
    };

    Reaver.prototype.stop = function() {
      if (this.proc) {
        this.proc.kill();
        return this.emit('exit', true);
      }
    };

    Reaver.prototype.process = function(data) {
      var key, matched, msg, msgs, pattern, res, _i, _len, _ref2, _results;
      msgs = data.toString('ascii').split('\n');
      _results = [];
      for (_i = 0, _len = msgs.length; _i < _len; _i++) {
        msg = msgs[_i];
        if (!(msg.length > 1)) continue;
        matched = false;
        for (key in REAVER_PATTERNS) {
          pattern = REAVER_PATTERNS[key];
          res = pattern.exec(msg);
          if (res) {
            matched = key;
            break;
          }
        }
        switch (matched) {
          case false:
            matched = "unhandled";
            res = [msg];
            break;
          case 'waitingBeacon':
            this.status.foundBeacon = false;
            break;
          case 'newChannel':
            this.status.channel = res[2];
            this.status.associated = false;
            break;
          case 'associated':
            this.status.foundBeacon = true;
            this.status.associated = true;
            break;
          case 'tryingPin':
            if (this.status.pin !== res[1]) {
              this.metrics.totalChecked++;
              this.metrics.consecutiveFailures = 0;
              if (this.status.phase === 0 && this.status.pin.slice(0, 4) === res[1].slice(0, 4)) {
                this.status.phase = 1;
                this.emit('completed', 1, {
                  pin: res[1].slice(0, 4)
                });
              }
              this.status.pin = res[1];
            }
            this.status.sequenceDepth = 0;
            break;
          case 'sending':
          case 'received':
            if (REAVER_PACKET_SEQ[res[1]] > this.status.sequenceDepth) {
              this.status.sequenceDepth = REAVER_PACKET_SEQ[res[1]];
            }
            break;
          case 'timedOut':
          case 'wpsFailure':
            this.metrics.consecutiveFailures++;
            this.metrics.totalFailures++;
            break;
          case 'rateLimit':
          case 'associateFailure':
            this.status.associated = false;
            this.status.locked = matched === 'rateLimit';
            this.status.sequenceDepth = -1;
            break;
          case 'consecutiveFailures':
            this.metrics.consecutiveFailures;
            break;
          case 'progress':
            this.metrics.secondsPerPin = (_ref2 = res[4]) != null ? _ref2 : null;
            break;
          case 'crackedPSK':
            this.emit('completed', 2, {
              psk: res[1]
            });
            break;
          case 'crackedPIN':
            this.emit('completed', 2, {
              pin: res[1]
            });
            break;
          case 'crackedTime':
            this.status.phase = 2;
            this.metrics.timeToCrack = res.slice(1, 3).join(' ');
            break;
          case 'crackedSSID':
            this.emit('completed', 2, {
              ssid: res[1]
            });
        }
        _results.push(this.emit('status', matched, this.status, res));
      }
      return _results;
    };

    return Reaver;

  })();

  module.exports = Reaver;

}).call(this);
