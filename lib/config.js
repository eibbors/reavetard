
  exports.REAVER_DEF_KEYS = ['1234', '0000', '0123', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '567', '000', '222', '333', '444', '555', '666', '777', '888', '999'];

  exports.WASH_DEFAULT_ARGS = {
    interface: 'mon0',
    ignoreFCS: true,
    scan: true
  };

  exports.REAVER_DEFAULT_ARGS = function(station) {
    return {
      veryVerbose: true,
      bssid: station.bssid,
      auto: true,
      channel: station.channel,
      dhSmall: true,
      noNacks: true,
      interface: 'mon0'
    };
  };
