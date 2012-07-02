(function() {
  var cli, config, db, reaver, rtard, startReaver, targetReview, wash, washSurvey;
  var _this = this;

  rtard = require('commander');

  cli = require('./cli');

  db = require('./db');

  wash = require('./wash');

  reaver = require('./reaver');

  config = require('./config');

  washSurvey = function(scan) {
    var rdb, stations, w;
    if (scan == null) scan = true;
    stations = {
      complete: [],
      inProgress: [],
      noHistory: []
    };
    rdb = new db();
    w = new wash({
      interface: 'mon0',
      scan: scan,
      ignoreFCS: true
    });
    w.on('ap', function(station) {
      return rdb.checkHistory(station.bssid, function(err, rows) {
        var k, v, _ref, _ref2;
        if (err) console.error(err);
        if (rows.length > 0) {
          _ref = rows[0];
          for (k in _ref) {
            v = _ref[k];
            if ((_ref2 = station[k]) == null) station[k] = v;
          }
          station.session = rdb.loadSession(station.bssid);
          if (station.attempts >= 11000 || station.session.phase === 2) {
            stations.complete.push(station);
            return logStation(station, 'C');
          } else {
            stations.inProgress.push(station);
            return logStation(station, 'W');
          }
        } else {
          stations.noHistory.push(station);
          return logStation(station, 'N');
        }
      });
    });
    w.on('exit', function() {
      console.log('wash process ended, beginning review');
      return targetReview(stations);
    });
    w.on('error', function() {
      return console.error("ERROR: " + arguments);
    });
    w.start();
    cli.cwrite('magenta', ' Wash scan now in progress, waiting for AP data...\n').cwrite('blue', ' (Press enter when satisfied with results to continue)');
    return rtard.prompt('\n', function(res) {
      w.stop();
      return console.log(res);
    });
  };

  targetReview = function(stations) {};

  startReaver = function(bssids) {};

  rtard.version('0.0.1').option('-i, --interface <iface>', 'Choose WLAN interface [mon0]', 'mon0').option('-r, --reaver-path [path]', 'Set path to your reaver.db and session files', '/usr/local/etc/reaver/').option('-d, --rdb-file [filename]', 'Set the filename of your reaver database', 'reaver.db');

  rtard.command('scan').description('Initiate an annotated wash survey').action(function() {
    cli.clear().title().cwrite('blue', ' Scan command chosen. Initializing wash survey...\n');
    return washSurvey();
  });

  rtard.command('crack <bssids>').description('Initiate reaver cracking session on one or more targets').action(startReaver);

  rtard.parse(process.argv);

}).call(this);
