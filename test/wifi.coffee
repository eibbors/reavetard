{airmon} = require '../src/wifi'

airmon.getInterfaces (ifaces) ->
  console.log 'airmon-ng compatible interfaces:\n', ifaces

airmon.getPhysicalInterfaces (phyfaces) ->
  console.log 'again, by physical interface:\n', phyfaces

airmon.start 'wlan2', (res, output) ->
  if res.enabledOn
    console.log "monitor mode enabled on #{res.enabledOn}"
    setTimeout((=> airmon.stop(res.enabledOn, console.log)) , 3000)
  if res.processes
    console.log "processes that may cause problems:", res.processes
  console.log "other interfaces:", res.interfaces
