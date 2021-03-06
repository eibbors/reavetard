// Generated by CoffeeScript 1.3.3
(function() {

  exports.CUSTOM_SETUP = function(cb) {
    return cb(true);
  };

  exports.DEFAULT_INTERFACE = 'mon0';

  exports.WASH_DEFAULT_ARGS = function(iface, scan) {
    var _ref;
    if (scan == null) {
      scan = true;
    }
    return {
      "interface": (_ref = iface != null ? iface : this.DEFAULT_INTERFACE) != null ? _ref : 'mon0',
      scan: scan,
      ignoreFCS: true
    };
  };

  exports.REAVER_DEFAULT_PATH = '/usr/local/etc/reaver/';

  exports.REAVER_DEFAULT_DBFILE = 'reaver.db';

  exports.REAVER_DEFAULT_KEYS = ['1234', '0000', '0123', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '567', '000', '222', '333', '444', '555', '666', '777', '888', '999'];

  exports.REAVER_DEFAULT_ARGS = function(station, iface) {
    var _ref, _ref1;
    return {
      veryVerbose: true,
      bssid: station.bssid,
      auto: true,
      "interface": (_ref = iface != null ? iface : this.DEFAULT_INTERFACE) != null ? _ref : 'mon0',
      channel: (_ref1 = station.channel) != null ? _ref1 : void 0,
      dhSmall: true,
      noNacks: true
    };
  };

  exports.CONSECUTIVE_FAILURE_LIMIT = 8;

  exports.HEALTH_CHECK_INTERVAL = 30000;

}).call(this);
