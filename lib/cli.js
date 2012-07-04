(function() {
  var REAVETARD_MENU, REAVETARD_TITLE, REAVETARD_TITLE_S, arrwrite, cdwrite, charm, commander, cwrite;
  var __slice = Array.prototype.slice;

  commander = require('commander');

  charm = require('charm')(process.stdout);

  arrwrite = function(arr, cd) {
    var a, _i, _len, _results;
    if (cd == null) cd = false;
    _results = [];
    for (_i = 0, _len = arr.length; _i < _len; _i++) {
      a = arr[_i];
      if (Array.isArray(a)) {
        if (cd) {
          _results.push(cdwrite.apply(null, a));
        } else {
          _results.push(cwrite.apply(null, a));
        }
      } else {
        if (cd) {
          _results.push(cdwrite.apply(null, [a]));
        } else {
          _results.push(cwrite.apply(null, [a]));
        }
      }
    }
    return _results;
  };

  cwrite = function() {
    if (arguments.length === 1) {
      return charm.write(arguments[0]);
    } else if (arguments.length >= 2) {
      charm.foreground(arguments[0]);
      if (arguments.length >= 3) {
        charm.background(arguments[1]);
        return charm.write(arguments.slice(2).join());
      } else {
        return charm.write(arguments[1]);
      }
    }
  };

  cdwrite = function() {
    var args, disp;
    disp = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    charm.display('reset');
    charm.display(disp);
    return cwrite.apply(null, args);
  };

  REAVETARD_TITLE = [['reset', 'blue', '                                      eibbors.com/p/reavetard/\n'], ['dim', 'magenta', ' -------------------------------------------------------------\n'], ['bright', 57, ' -  ▀█▀▀▀▄ ▄▀▀▀▄ ▀▀▀▀▄ █   █ ▄▀▀▀▄ ▄█▄▄  ▀▀▀▀▄ ▀█▀▀▀▄   ▀█   -\n'], ['bright', 56, ' -   █  ▀  █▀▀▀▀ █▀▀▀█ ▀▄ ▄▀ █▀▀▀▀  █  ▄ █▀▀▀█  █  ▀ ▄▀▀▀█   -\n'], ['bright', 55, ' -   ▀▀     ▀▀▀▀  ▀▀▀ ▀  ▀    ▀▀▀▀   ▀▀▀  ▀▀▀ ▀ ▀▀    ▀▀▀▀▀  -\n'], ['reset', 'blue', ' -    ~ Reaver Tools for AP Rotation & Data Management  ~    -\n'], ['dim', 'magenta', ' -------------------------------------------------------------\n'], ['reset', '\n']];

  REAVETARD_TITLE_S = [['bright', 57, '  __   _   _  _ _  _  ___ _  __   _   \n'], ['bright', 56, '  |_| |_|  _| | | |_|  |  _| | | _|   '], ['reset', 'blue', 'CoffeeScript goodies for Reaver-WPS'], ['bright', 55, '  | \ |__ |_\  V  |__  | |_\ |  |_|_  '], ['reset', 'blue', 'Courtesy of Robbie Saunders (eibbors.com)\n'], ['magenta', '_________________________________________________________________________________']];

  REAVETARD_MENU = [];

  exports.title = function(full) {
    if (full == null) full = true;
    if (full) {
      arrwrite(REAVETARD_TITLE, true);
    } else {
      arrwrite(REAVETARD_TITLE_S, true);
    }
    return this;
  };

  exports.menu = function() {
    arrwrite(REAVETARD_MENU, true);
    return this;
  };

  exports.washHit = function(station, status) {
    var c, colors, _ref;
    colors = {
      C: 72,
      W: 'blue',
      N: 5
    };
    c = colors[status];
    if (station.locked) c = 'red';
    this.label(c, 'st', status);
    this.label(c, 'rssi', station.rssi);
    this.label(c, 'bssid', station.bssid);
    this.label(c, 'ch', station.channel);
    this.label(c, 'essid', station.essid);
    if (status === 'C') {
      this.label(c, 'pin', (_ref = station.session) != null ? _ref.pin : void 0);
      this.label(c, 'key', station.key);
      this.label(c, 'checked', Number(station.session.ki1) + Number(station.session.ki2));
    } else if (status === 'W') {
      this.label(c, 'progress', "" + (Number(station.attempts / 110).toFixed(2)) + "%");
      this.label(c, 'phase', station.session.phase);
      this.label(c, 'checks', Number(station.session.ki1) + Number(station.session.ki2));
      if (station.attempts > 10000 || station.session.phase === 1) {
        this.label(c, 'pin', "" + station.session.pin);
      }
    }
    if (station.device != null) {
      this.label(c, 'device', station.device.name);
      this.label(c, 'manuf.', station.device.manufacturer);
      this.label(c, 'model', "" + station.device.model + "/" + station.device.number);
    }
    if (station.locked) this.label(c, '!', 'LOCKED');
    charm.write('\n');
    return this;
  };

  exports.label = function(fg, ltext, rtext) {
    charm.display('reset').foreground(fg).write("" + ltext + "/");
    charm.display('bright').foreground(fg).write("" + rtext + " ").display('reset');
    return this;
  };

  exports.labels = function(color, keys, obj) {
    var key, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      key = keys[_i];
      _results.push(this.label(color, key, obj[key]));
    }
    return _results;
  };

  exports.cwrite = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    cwrite.apply(null, args);
    return this;
  };

  exports.cdwrite = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    cdwrite.apply(null, args);
    return this;
  };

  exports.clear = function() {
    charm.erase('screen');
    charm.position(0, 0);
    return this;
  };

  exports.write = charm.write;

  exports.erase = charm.erase;

  exports.foreground = charm.foreground;

  exports.background = charm.background;

  exports.display = charm.display;

  exports._c = charm;

}).call(this);
