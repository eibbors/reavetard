(function() {
  var REAVER_DEF_KEYS, WPSPinCollection, calcChecksum, enumKeys, padKey;

  REAVER_DEF_KEYS = require('./config').REAVER_DEF_KEYS;

  padKey = function(key, width) {
    var len;
    len = Math.max(0, width - key.length);
    return Array(len + 1).join('0') + key;
  };

  calcChecksum = function(pin) {
    var accum;
    accum = 0;
    while (pin > 0) {
      accum += 3 * (pin % 10);
      pin = parseInt(pin / 10);
      accum += pin % 10;
      pin = parseInt(pin / 10);
    }
    return (10 - accum % 10) % 10;
  };

  enumKeys = function(klen) {
    var i, max, _results;
    max = Math.pow(10, klen);
    _results = [];
    for (i = 0; 0 <= max ? i < max : i > max; 0 <= max ? i++ : i--) {
      _results.push(padKey("" + i, klen));
    }
    return _results;
  };

  WPSPinCollection = (function() {

    function WPSPinCollection(explicits) {
      var k, _i, _len;
      var _this = this;
      this.keys = {
        '1': [],
        '2': []
      };
      this.keys.add = function(key) {
        var _ref;
        if ((_ref = key.length) === 7 || _ref === 8) {
          _this.keys[1].push(key.slice(0, 4));
          _this.keys[2].push(key.slice(4, 7));
        }
        if (key.length === 4) _this.keys[1].push(key);
        if (key.length === 3) return _this.keys[2].push(key);
      };
      if (explicits == null) explicits = REAVER_DEF_KEYS;
      for (_i = 0, _len = explicits.length; _i < _len; _i++) {
        k = explicits[_i];
        this.keys.add(k);
      }
    }

    WPSPinCollection.prototype.keyAt = function(set, kindex, pad) {
      var k, key, keys, _i, _len, _ref;
      if (pad == null) pad = true;
      keys = this.keys[set];
      if (kindex >= keys.length) {
        key = kindex - keys.length;
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          k = keys[_i];
          if (Number(k) < (kindex - 1)) key++;
        }
      } else {
        key = (_ref = keys[kindex]) != null ? _ref : '0000';
      }
      if (pad) {
        return padKey(key, 5 - set);
      } else {
        return key;
      }
    };

    WPSPinCollection.prototype.get = function(ki1, ki2) {
      var cs, p1, p2;
      p1 = "" + (this.keyAt(1, ki1));
      p2 = "" + (this.keyAt(2, ki2));
      cs = calcChecksum(Number(p1 + p2));
      return "" + p1 + p2 + cs;
    };

    WPSPinCollection.prototype.buildEnum = function() {
      var i, k, kset, removed, _i, _len, _ref;
      kset = {
        '1': enumKeys(4),
        '2': enumKeys(3)
      };
      for (i = 1; i <= 2; i++) {
        removed = 0;
        _ref = this.keys[i].slice(0).sort();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          kset[i].splice(Number(k) - removed++, 1);
        }
      }
      return this.keys[1].concat(kset[1], this.keys[2], kset[2]);
    };

    return WPSPinCollection;

  })();

  module.exports = WPSPinCollection;

}).call(this);
