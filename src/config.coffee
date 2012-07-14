# Reavetard - Reaver WPS (+Wash) extension scripts
# config.coffee :: This module contains user-defined constants, default values 
#   for some variables/arguments, and functions that control runtime event 
#   triggers and/or workflows. 
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# You can use this function to do whatever you want, such as putting your 
# interface in monitor mode and/or changing its mac address. Just be sure to
# call the cb function with (true) to continue or (false, err) to abort
exports.CUSTOM_SETUP = (cb) ->
  # See wifi.coffee in tests folder for help using airmon, i(w|f)config, etc.
  cb true

# I use mon0 999/1000 times. Set this to whateve you normally use and you can
# leave the -i argument off when running reavetard
exports.DEFAULT_INTERFACE = 'mon0'

# These settings will be just dandy most of the time, but if you want to use
# 5ghz channels or default to a different interface, etc, they're here
exports.WASH_DEFAULT_ARGS = (iface, scan=true) ->
  interface: iface ? @DEFAULT_INTERFACE ? 'mon0'
  scan: scan
  ignoreFCS: true # These errors are ignored on our end, so...
  # use5ghz = true # enable 5ghz channel support
  # See WASH_ARGS in wash.coffee for a complete list of possible args

# If you'd like to use non-standard reaver data path or db-file by default,
# then simply change the following two settings:
exports.REAVER_DEFAULT_PATH = '/usr/local/etc/reaver/'
exports.REAVER_DEFAULT_DBFILE = 'reaver.db'

# Reaver 1.3+, by default, explicitly defines these keys then sequentially
# exhausts the remaining keys. You can tune these to better match your
# own mileage or update these should Reaver's values change.
exports.REAVER_DEFAULT_KEYS = [  
  '1234', '0000', '0123', '1111', '2222', '3333', '4444', '5555', 
  '6666', '7777', '8888', '9999', '567',  '000',  '222',  '333',  
  '444',  '555',  '666',  '777',  '888',  '999'
  ]

# Reaver's default configuration provides the station it will be targetting
# These values have worked for me across all vulnerable devices so far...
exports.REAVER_DEFAULT_ARGS = (station, iface) ->
  veryVerbose: true
  bssid: station.bssid
  auto: true 
  interface: iface ? @DEFAULT_INTERFACE ? 'mon0'
  # DO NOT REMOVE ANY REAVER ARGS ABOVE THIS LINE ----------------------------
  channel: station.channel ? undefined # Channel hopping is the enemy of multi-ap cracking performance
  dhSmall: true # Improves crack speed 
  noNacks: true # A necessecity for long range cracking, since many AP's will send packets in bursts
  # See REAVER_ARGS in reaver.coffee for a complete list of possible args

# This lets you set how many consecutive failures are allowed before assuming
# the current target is at least temporarily a bust
exports.CONSECUTIVE_FAILURE_LIMIT = 8

# Interval reavetard should wait between health checks
exports.HEALTH_CHECK_INTERVAL = 30000 # milliseconds
