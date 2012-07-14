# Reavetard Wifi Module Tests - Author: Robbie Saunders
# Test Linux interface configuration commands from wifi.coffee

# Change these to match your interface names before running
DEV1 = 'wlan1'
DEV2 = 'wlan2'
DEV3 = 'eth1'

# Import wifi command `namespaces`
{airmon, iwconfig, ifconfig} = require '../src/wifi'

# airmon-ng 
# -------------------------
airmon.getInterfaces (ifaces) ->
  console.log 'airmon-ng compatible interfaces:\n', ifaces

airmon.getPhysicalInterfaces (phyfaces) ->
  console.log 'again, by physical interface:\n', phyfaces

airmon.start "#{DEV2}", (res, output) ->
  if res.enabledOn
    console.log "monitor mode enabled on #{res.enabledOn}"
    setTimeout((=> airmon.stop(res.enabledOn, console.log)) , 3000)
  if res.processes
    console.log "processes that may cause problems:", res.processes
  console.log "other interfaces:", res.interfaces

# iwconfig
# -------------------------
iwconfig.run '', (err, ifaces) ->
  console.log 'iwconfig returned the following interface data:\n', ifaces

iwconfig.checkWifiSetup "#{DEV1}", (err, ifaces) ->
  console.log "iwconfig + select #{DEV1} data:\n", ifaces

iwconfig.checkWifiSetup 'poop', (err, ifaces) ->
  console.log 'iwconfig + bogus iface:\n', err, ifaces

# ifconfig + macchanger
# -------------------------
ifconfig.all (err, ifaces) ->
  console.log 'ifconfig returned following interfaces:\n', ifaces

ifconfig.down "#{DEV1}", (err, success) ->
  console.log "ifconfig took #{DEV1} down? #{success or err}"