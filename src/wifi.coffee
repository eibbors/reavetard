# Reavetard - Reaver WPS (+Wash) extension scripts
# wifi.coffee :: Overly complicated module to automate various wifi adapter tasks
#   such as enabling/disabling monitor mode, changing the MAC address, etc.
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# Module dependencies
# -------------------------
{exec} = require 'child_process'
cli = require './cli'

# airmon-ng commands to start, stop, and check wlan adapter monitor mode 
# ----------------------------------------------------------------------
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

  # Check for possible `problem processes`
  check: (cb) ->
    @run ['check'], cb

  # Try to kill the processes returned by check/start
  kill: (cb) ->
    @run ['check', 'kill'], cb


# iwconfig command - view/edit wireless adapter settings, 
# ----------------------------------------------------------------------
iwconfig = exports.iwconfig =

  # Execute iwconfig and call your cb function with its parsed output
  run: (args, cb) =>
    if Array.isArray(args) then args = args.join ' '
    if args then cmd = "iwconfig #{args}" else cmd = 'iwconfig'
    exec cmd, {}, (err, stdout, stderr) =>
      if err then return cb err, false 
      interfaces = []
      # Split by 2 newlines (with(out) spaces too) in a row    
      sections = stdout.split /\n\s*\n/ 
      for section in sections
        # Parse the iface & supported 802.11 standards / "field-like" strings
        iwname = /(\w+)\s+IEEE 802\.11(\w+)/.exec section
        iwflds = section.match /\s\s+((\S+\s?)+)(:|=)\s?((\S+\s?)+)/g
        if iwname # Once we know its name we need to rename and trim our fields 
          iwtmp = { name: iwname[1], supports: iwname[2].split('') }
          for flds in iwflds
            fld = flds.split(/(:|=)/)
            if fld.length > 3 # Fixes Access Point Bssid, which contains :'s
              fld[2] = fld[2..].join('')
            fld[0] = fld[0].replace('-', ' ').trim()
            fld[0] = fld[0].toLowerCase().replace(/(\s+\w)/g, (m) -> m.trim().toUpperCase())
            fld[2] = fld[2].trim()
            iwtmp[fld[0]] = fld[2]
          interfaces.push iwtmp
      cb err, interfaces

  # Same as running with no args, but can be used to check for the existence of
  # or simply to filter out a single interface
  checkWifiSetup: (iface, cb) ->
    if iface
      @run '', (err, interfaces) ->
        for i in interfaces
          if i.name is iface
            return cb err, i
        cb "Error: Interface #{iface} not found!", false
    else
      @run '', cb 

# ifconfig - commands for configuring network interfaces
# ----------------------------------------------------------------------
ifconfig = exports.ifconfig = 

  # Execute ifconfig and parse the output... the output that seems horribly
  # inconsistently formatted. If I'm missing a pattern or trick to handling
  # all the different possibilities besides hardcoding them one by one as 
  # I'm currently doing, please enlighten me!
  run: (args, cb) =>
    if Array.isArray(args) then args = args.join ' '
    if args then cmd = "ifconfig #{args}" else cmd = 'ifconfig'
    exec cmd, {}, (err, stdout, stderr) =>
      if err then return cb err, false 
      interfaces = []
      # Split by 2 newlines (with(out) spaces too) in a row    
      sections = stdout.split /\n\s*\n/ 
      for section in sections
        lines = section.split '\n'
        for line in lines
          decl = /^(\w+)\s+Link encap:((\s?\w+)+)  (HWaddr (\S+)  )?/i.exec line
          if decl # Fairly straightforward 
            if lastiface? then interfaces.push lastiface
            lastiface = { name: decl[1], type: decl[2], mac: decl[5] }
            decl = false
          else # I have to be missing a trick... Please clean me up!
            pieces = line.split(/\s\s+/)
            for piece in pieces[1..]
              attrs = piece.match(/(RX |TX |inet |inet6 )?((\S+):\s?(\S+))+/g)
              if attrs?.length? >= 1
                attcat = attrs[0].split(' ')
                if attcat?.length is 1 # RX ...\n {child:val} || {Normal:val}
                  ischild = /^([a-z]+):(.*)/g.exec attcat[0]
                  if ischild and lastcat 
                    lastiface[lastcat][ischild[1]] = ischild[2]
                    ismore = attrs[1].split ':'
                    if ismore.length > 1
                      lastiface[lastcat][ismore[0]] = ismore[1]
                  else
                    attr = attcat[0].split(':')
                    lastiface[attr[0]] = attr[1]
                else if attcat?.length is 2 # RX/TX/inet(6) a:1 b:2 ...
                  lastcat = attcat[0]
                  attr = attcat[1].split(':')
                  lastiface[lastcat] ?= {}
                  lastiface[lastcat][attr[0]] = attr[attr.length - 1]
                  for attr in attrs[1..]
                    attr = attr.split(':')
                    lastiface[lastcat][attr[0]] = attr[attr.length - 1]
                else if attcat?.length is 3 # inet6 addr: 121:14:14:...
                  lastcat = attcat[0]
                  lastiface[lastcat] ?= {}
                  lastiface[lastcat][attcat[1].replace(':','')] = attcat[2]
              else
                if /([A-Z]+ ?)+/g.test piece
                  lastiface.flags = piece.split(' ')
      interfaces.push lastiface # push the final interface
      cb err, interfaces

  all: (cb) ->
    @run '-a', cb

  up: (iface, cb) ->
    @run "#{iface} up",  (err) ->
      if err then cb err, false
      else cb null, true

  down: (iface, cb) ->
    @run "#{iface} down", (err) ->
      if err then cb err, false
      else cb null, true

