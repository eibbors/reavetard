# Reavetard - Reaver WPS (+Wash) extension scripts
# wifi.coffee :: Overly complicated module to automate various wifi adapter tasks
#   such as enabling/disabling monitor mode, changing the MAC address, etc.
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
{exec} = require 'child_process'
cli = require './cli'

airmon = exports.airmon = 

  # Execute airmon-ng + args and call back fancy parsed output
  run: (args, cb) ->
    if Array.isArray(args) then args = args.join ' '
    if args then cmd = "airmon-ng #{args}" else cmd = "airmon-ng"
    exec cmd, {}, (err, stdout, stderr) =>
      isIfaces = false 
      results = {}
      if err then throw(err)
      else if stdout
        for section in stdout.split('\n\n')
          lines = section.split('\n')
          # Possible problem processes included in output
          if lines[0] is 'PID\tName'
            results.processes = {}
            for line in lines[1..]
              proc = /(\d+)\t(\w+)/.exec line
              if proc then results.processes[proc[1]] = { pid: proc[1], name: proc[2] }
              else 
                oniface = /Process with PID (\d+) \((.*)\) is running on interface (.*)/.exec line
                if oniface then results.processes[oniface[1]].runningOn = oniface[3]
          # Grab interfaces, should there be any (these columns are always one section before)
          if /Interface\tChipset\t\tDriver/g.test section
            isIfaces = true
          else if isIfaces
            isIfaces = false
            results.interfaces = []
            for line in lines 
              # This regex was hard on my eyes for some reason, so I split it up into parts
              ifrow = ///
                ([^\t]+)\t+
                ([^\t]+)\t+
                (\w+)\s-\s
                \[(\w+)\]
                (\s+\(removed\))?///.exec line
              if ifrow then results.interfaces.push
                interface:  ifrow[1] 
                chipset:    ifrow[2]
                driver:     ifrow[3]
                phyid:      ifrow[4]
                removed:    ifrow[5] is ' (removed)'
              else
                monok = /\s+\(monitor mode enabled on (\w+)\)/.exec line
                if monok then results.enabledOn = monok[1]
        cb results, stdout, stderr 


  # Run with no arguments, used to search for all compatible ifaces
  getInterfaces: (cb) ->
    @run undefined, (res) -> 
      cb res.interfaces

  # Return results of above, categorized by phyical name ie:
  # { phy0: [{mon0}, {wlan2}], phy1: [{wlan1}] }
  # Useful for determining which cards aren't yet in monitor mode
  getPhysicalInterfaces: (cb) ->
    @getInterfaces (ifaces) ->
      phys = {}
      for iface in ifaces
        phys[iface.phyid] ?= []
        phys[iface.phyid].push iface
      cb phys
  
  # Start monitor mode on an interface, return parsed results via callback
  # Optionally, restrict monitor mode to a single channel with channel arg
  start: (iface, cb, channel=false) ->
    cmd = ['start', iface]
    if channel then cmd.push channel
    @run cmd, (res) ->
      if res.enabledOn?.length > 0
        res.success = true
      else
        res.success = false
      cb res
        
  # Stop monitor mode 
  stop: (iface, cb) ->
    @run ['stop', iface], (res) ->
      res.success = false 
      for iface in res.interfaces
        if iface.removed then res.success = true
      cb res

  check: (cb) ->
    @run ['stop', iface], (res) ->
      res.success = false 
      for iface in res.interfaces
        if iface.removed then res.success = true
      cb res

# iwconfig command - read/write configuration of wireless adapters
# ----------------------------------------------------------------------
iwconfig = exports.iwconfig =

  # Execute iwconfig and call your cb function with its parsed output
  run: (args, cb) ->
    if Array.isArray(args) then args = args.join ' '
    if args then cmd = "iwconfig #{args}" else cmd = 'iwconfig'
    exec cmd, {}, (err, stdout, stderr) =>
      console.log err, stdout, stderr

