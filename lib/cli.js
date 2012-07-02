(function() {
  var REAVETARD_MENU, REAVETARD_TITLE, REAVETARD_TITLE_S, arrwrite, cdwrite, charm, commander, cwrite, exit;
  var __slice = Array.prototype.slice;

  commander = require('commander');

  charm = require('charm')(process.stdout);

  exit = function() {
    charm.display('reset');
    return process.exit();
  };

  charm.on('^C', exit);

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
        if (cd) cdwrite.apply(null, [a]);
        _results.push(cwrite.apply(null, [a]));
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
    if (arguments.length >= 2) {
      charm.display('reset');
      charm.display(arguments[0]);
      return cwrite.apply(null, arguments.slice(1));
    }
  };

  REAVETARD_TITLE = [['reset', 'blue', '                                      eibbors.com/p/reavetard/\n'], ['dim', 'magenta', ' -------------------------------------------------------------\n'], ['bright', 57, ' -  ▀█▀▀▀▄ ▄▀▀▀▄ ▀▀▀▀▄ █   █ ▄▀▀▀▄ ▄█▄▄  ▀▀▀▀▄ ▀█▀▀▀▄   ▀█   -\n'], ['bright', 56, ' -   █  ▀  █▀▀▀▀ █▀▀▀█ ▀▄ ▄▀ █▀▀▀▀  █  ▄ █▀▀▀█  █  ▀ ▄▀▀▀█   -\n'], ['bright', 55, ' -   ▀▀     ▀▀▀▀  ▀▀▀ ▀  ▀    ▀▀▀▀   ▀▀▀  ▀▀▀ ▀ ▀▀    ▀▀▀▀▀  -\n'], ['reset', 'blue', ' -    ~ Reaver Tools for AP Rotation & Data Management  ~    -\n'], ['dim', 'magenta', ' -------------------------------------------------------------\n\n']];

  REAVETARD_TITLE_S = [['bright', 57, '  __   _   _  _ _  _  ___ _  __   _   \n'], ['bright', 56, '  |_| |_|  _| | | |_|  |  _| | | _|   '], ['reset', 'blue', 'CoffeeScript goodies for Reaver-WPS'], ['bright', 55, '  | \ |__ |_\  V  |__  | |_\ |  |_|_  '], ['reset', 'blue', 'Courtesy of Robbie Saunders (eibbors.com)\n'], ['magenta', '_________________________________________________________________________________']];

  REAVETARD_MENU = [];

  exports.title = function(full) {
    if (full == null) full = true;
    if (full) {
      arrwrite(REAVETARD_TITLE, false);
    } else {
      arrwrite(REAVETARD_TITLE_S, false);
    }
    return this;
  };

  exports.menu = function() {
    arrwrite(REAVETARD_MENU);
    return this;
  };

  exports.washHit = function(station, status) {
    var progress, _ref;
    if (station.locked) charm.display('dim');
    if (status === 'C') {
      cwrite(57, "[C] rssi:" + station.rssi + " bssid:" + station.bssid + " ch:" + ch + " essid:'" + station.essid + "'\n");
      cwrite(57, " |- pin:" + ((_ref = station.session) != null ? _ref.pin : void 0) + " key:'" + station.key + "'");
    } else if (status === 'W') {
      progress = Number(station.attempts / 110).toFixed(2) + '%';
      if (station.attempts > 10000 || station.session.phase === 1) {
        progress += " pin:" + station.session.pin + "____";
      }
      cwrite('magenta', "[W] rssi:" + station.rssi + " bssid:" + station.bssid + " ch:" + ch + " essid:'" + station.essid + "'\n");
      cwrite('magenta', " |- eliminated:" + station.attempts + "/11000 ~" + progress + " phase:" + station.phase);
    } else if (status === 'N') {
      cwrite('blue', "[C] rssi:" + station.rssi + " bssid:" + station.bssid + " ch:" + ch + " essid:'" + station.essid + "'");
    }
    if (station.locked) {
      cdwrite('bright', 'red', ' locked\n');
    } else {
      cwrite('green', ' unlocked\n');
    }
    cdwrite('reset', '\n');
    return this;
  };

  exports.label = function(ltext, rtext, enabled) {
    if (enabled == null) enabled = true;
    charm.display('bright');
    charm.write(ltext);
    if (enabled) {
      charm.display('reset');
    } else {
      charm.display('dim');
    }
    charm.write(rtext);
    return this;
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
