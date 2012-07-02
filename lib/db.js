(function() {
  var Pins, ReaverData, fs, sqlite3;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  sqlite3 = require('sqlite3').verbose();

  fs = require('fs');

  Pins = require('./pins');

  ReaverData = (function() {

    function ReaverData(rvrPath, dbFile) {
      this.rvrPath = rvrPath != null ? rvrPath : '/usr/local/etc/reaver/';
      this.dbFile = dbFile != null ? dbFile : 'reaver.db';
      this.loadSession = __bind(this.loadSession, this);
      if (this.rvrPath.slice(-1) !== '/') this.rvrPath += '/';
      this.db = new sqlite3.Database("" + this.rvrPath + this.dbFile);
    }

    ReaverData.prototype.getHistory = function(cb) {
      return this.db.all("SELECT * FROM history ORDER BY timestamp DESC", cb);
    };

    ReaverData.prototype.getSurvey = function(cb) {
      return this.db.all("SELECT * FROM survey ", cb);
    };

    ReaverData.prototype.getStatus = function(cb) {
      return this.db.all("SELECT * FROM status", cb);
    };

    ReaverData.prototype.checkHistory = function(bssid, cb) {
      return this.db.all("SELECT * FROM history WHERE bssid = '" + bssid + "'", cb);
    };

    ReaverData.prototype.loadSession = function(bssid, filename) {
      var ki1, ki2, phase, pin, pset, session;
      if ((bssid != null) && !(filename != null)) {
        filename = ("" + this.rvrPath + bssid + ".wpc").replace(/:/g, '');
      }
      try {
        session = fs.readFileSync(filename, 'utf8');
        session = session.split("\n");
      } catch (error) {
        session = [0, 0, 0, []];
      }
      pset = new Pins(session.slice(3, -1));
      ki1 = session[0];
      ki2 = session[1];
      phase = session[2];
      switch (phase) {
        case '2':
          pin = pset.get(ki1, ki2);
          break;
        case '1':
          pin = pset.keyAt(1, ki1);
          break;
        case '0':
          pin = null;
      }
      return {
        phase: phase,
        pin: pin,
        Pins: pset,
        ki1: ki1,
        ki2: ki2
      };
    };

    ReaverData.prototype.writeSession = function(bssid, phase, ki1, ki2, pins, filename) {
      var output;
      if (phase == null) phase = 0;
      if (ki1 == null) ki1 = 0;
      if (ki2 == null) ki2 = 0;
      if (filename == null) {
        filename = ("" + this.rvrPath + bssid + ".wpc").replace(/:/g, '');
      }
      if (pins == null) pins = new Pins();
      if (Array.isArray(pins)) {
        pins = new Pins(pins);
      } else if (typeof pins === 'string') {
        pins = new Pins(pins.split('\n'));
      }
      output = "" + ki1 + "\n" + ki2 + "\n" + phase + "\n" + (pins.buildEnum().join('\n'));
      return fs.writeFileSync(filename, output, 'utf8');
    };

    return ReaverData;

  })();

  module.exports = ReaverData;

}).call(this);
