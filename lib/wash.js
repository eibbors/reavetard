(function() {
  var WASH_ARGS, Wash, events, exec, spawn, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  events = require('events');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  WASH_ARGS = {
    interface: ['-i', '--interface=<iface>', 'Interface to capture packets on', true],
    file: ['-f', '--file [FILE1 FILE2 FILE3 ...]', 'Read packets from capture files', true],
    channel: ['-c', '--channel=<num>', 'Channel to listen on [auto]', true],
    outFile: ['-o', '--out-file=<file>', 'Write data to file', true],
    probes: ['-n', '--probes=<num>', 'Maximum number of probes to send to each AP in scan mode [15]', true],
    daemonize: ['-D', '--daemonize', 'Daemonize wash', false],
    ignoreFCS: ['-C', '--ignore-fcs', 'Ignore frame checksum errors', false],
    use5ghz: ['-5', '--5ghz', 'Use 5GHz 802.11 channels', false],
    scan: ['-s', '--scan', 'Use scan mode', false],
    survey: ['-u', '--survey', 'Use survey mode [default]', false],
    help: ['-h', '--help', 'Show help', false]
  };

  /* Child process wrapper for spawned wash processes
  */

  Wash = (function() {

    __extends(Wash, events.EventEmitter);

    function Wash(options) {
      this.process = __bind(this.process, this);
      var key, value, _ref2, _ref3;
      for (key in options) {
        if (!__hasProp.call(options, key)) continue;
        value = options[key];
        this[key] = value;
      }
      if ((_ref2 = this.interface) == null) this.interface = 'mon0';
      if ((_ref3 = this.scan) == null) this.scan = true;
      this.proc = null;
    }

    Wash.prototype.start = function(args, duration) {
      var desc, flag, inclVal, key, option, value;
      var _this = this;
      if (duration == null) duration = 0;
      if (!(args != null)) {
        args = [];
        for (key in WASH_ARGS) {
          value = WASH_ARGS[key];
          if (!(this[key] != null)) continue;
          flag = value[0], option = value[1], desc = value[2], inclVal = value[3];
          if (this[key] || inclVal) args.push(flag);
          if (inclVal) args.push(this[key]);
        }
      }
      this.stop();
      if (duration > 0) {
        this.proc = void 0;
        return exec('wash', args, function(output) {
          var line, _i, _len, _ref2, _results;
          _ref2 = output.split('\n');
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            line = _ref2[_i];
            _results.push(_this.process(line));
          }
          return _results;
        });
      } else {
        this.proc = spawn('wash', args);
        this.proc.stdout.on('data', this.process);
        return this.proc.stderr.on('data', this.process);
      }
    };

    Wash.prototype.stop = function() {
      if (this.proc) {
        this.proc.kill();
        return this.emit('exit', true);
      }
    };

    Wash.prototype.process = function(data) {
      var ap;
      ap = /(\w\w(:\w\w)+)\s+(\d+)\s+(-\d+)\s+(\d\.\d)\s+(Yes|No)\s+(.*)/.exec(data.toString());
      if (ap) {
        return this.emit('ap', {
          bssid: ap[1],
          channel: ap[3],
          rssi: ap[4],
          version: ap[5],
          locked: ap[6] === 'Yes',
          essid: ap[7]
        });
      }
    };

    return Wash;

  })();

  module.exports = Wash;

}).call(this);
