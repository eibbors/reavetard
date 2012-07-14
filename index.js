// Require the main reavetard module
var reavetard = module.exports = require('./lib/reavetard');

// Parse commandline options when run directly
if (module === require.main) {
	reavetard.parseOptions(process.argv);
}