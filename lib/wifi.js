(function() {
  var airmon, cli, exec;

  exec = require('child_process').exec;

  cli = require('./cli');

  airmon = exports.airmon = {
    run: function(args, cb) {
      var cmd;
      var _this = this;
      if (Array.isArray(args)) args = args.join(' ');
      if (args) {
        cmd = "airmon-ng " + args;
      } else {
        cmd = "airmon-ng";
      }
      return exec(cmd, {}, function(err, stdout, stderr) {
        var ifrow, isIfaces, line, lines, monok, oniface, proc, results, section, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
        isIfaces = false;
        results = {};
        if (err) {
          throw err;
        } else if (stdout) {
          _ref = stdout.split('\n\n');
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            section = _ref[_i];
            lines = section.split('\n');
            if (lines[0] === 'PID\tName') {
              results.processes = {};
              _ref2 = lines.slice(1);
              for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
                line = _ref2[_j];
                proc = /(\d+)\t(\w+)/.exec(line);
                if (proc) {
                  results.processes[proc[1]] = {
                    pid: proc[1],
                    name: proc[2]
                  };
                } else {
                  oniface = /Process with PID (\d+) \((.*)\) is running on interface (.*)/.exec(line);
                  if (oniface) {
                    results.processes[oniface[1]].runningOn = oniface[3];
                  }
                }
              }
            }
            if (/Interface\tChipset\t\tDriver/g.test(section)) {
              isIfaces = true;
            } else if (isIfaces) {
              isIfaces = false;
              results.interfaces = [];
              for (_k = 0, _len3 = lines.length; _k < _len3; _k++) {
                line = lines[_k];
                ifrow = /([^\t]+)\t+([^\t]+)\t+(\w+)\s-\s\[(\w+)\](\s+\(removed\))?/.exec(line);
                if (ifrow) {
                  results.interfaces.push({
                    interface: ifrow[1],
                    chipset: ifrow[2],
                    driver: ifrow[3],
                    phyid: ifrow[4],
                    removed: ifrow[5] === ' (removed)'
                  });
                } else {
                  monok = /\s+\(monitor mode enabled on (\w+)\)/.exec(line);
                  if (monok) results.newMon = monok[1];
                }
              }
            }
          }
          return cb(results, stdout, stderr);
        }
      });
    },
    getInterfaces: function(cb) {
      return this.run(void 0, function(res) {
        return cb(res.interfaces);
      });
    },
    getPhysicalInterfaces: function(cb) {
      return this.getInterfaces(function(ifaces) {
        var iface, phys, pi, _i, _len, _ref, _ref2;
        phys = {};
        for (_i = 0, _len = ifaces.length; _i < _len; _i++) {
          iface = ifaces[_i];
          if (((_ref = iface.driver) != null ? _ref.length : void 0) != null) {
            pi = iface.driver[1].slice(1, -1);
            if ((_ref2 = phys[pi]) == null) phys[pi] = [];
            phys[pi].push(iface);
          }
        }
        return cb(phys);
      });
    },
    start: function(iface, cb) {
      return this.run(['start', iface], function(res, sout) {
        if (res.newMon) {
          return cb(res.newMon);
        } else {
          throw "ERROR: Monitor mode not enabled? See output:\n'''\n" + sout + "\n'''";
        }
      });
    },
    stop: function(iface, cb) {
      return this.run(['stop', iface], cb);
    }
  };

  airmon.start('wlan1', console.log);

  setTimeout(function() {
    return airmon.stop("mon0", console.log, 4000);
  });

}).call(this);
