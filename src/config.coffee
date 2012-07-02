# Reavetard - Reaver WPS (+Wash) extension scripts
# config.coffee :: This module contains user-defined constants, default values 
#   for some variables/arguments, and functions that control runtime event 
#   triggers and/or workflows. 
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Reaver 1.3+, by default, explicitly defines these keys then sequentially
# exhausts the remaining keys. You can tune these to better match your
# own mileage or update these should Reaver's values change.
exports.REAVER_DEF_KEYS = [  
  '1234', '0000', '0123', '1111', '2222', '3333', '4444', '5555', 
  '6666', '7777', '8888', '9999', '567',  '000',  '222',  '333',  
  '444',  '555',  '666',  '777',  '888',  '999'
  ]

# These settings will be just dandy most of the time, but if you want to use
# 5ghz channels or default to a different interface, etc, they're here
exports.WASH_DEFAULT_ARGS =
  interface: 'mon0'
  ignoreFCS: true
  scan: true # 
  # use5ghz = true # enable 5ghz channel support
  # ... See WASH_ARGS in wash.coffee for more http.Agent options

# Reaver's default configuration provides the station it will be targetting
# These values have worked for me across all vulnerable devices so far...
exports.REAVER_DEFAULT_ARGS = (station) ->
  veryVerbose: true # DO NOT REMOVE
  bssid: station.bssid # DO NOT REMOVE
  auto: true 
  # DO NOT REMOVE ANYTHING ABOVE THIS LINE
  channel: station.channel # Channel hopping is the enemy of multi-ap cracking
  dhSmall: true # Improves crack speed
  noNacks: true # A necessecity for long range cracking because of flooding
  # ANYTHING BEFORE THIS LINE SHOULD RARELY NEED TO BE CHANGED
  interface: 'mon0'



