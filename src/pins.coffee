# Reavetard - Reaver WPS (+Wash) extension scripts
# pins.coffee :: Convenient WPS PIN collection class that can calculate standard
#   the pins based on indices or keys to save resources when 
# Author: Robbie Saunders http://eibbors.com/[/p/reavetard]
# ==============================================================================

# These are supposedly common reaver explicitly defines them by default.
{REAVER_DEF_KEYS} = require './config'

# Pad (prepend 0's to) an integer to its proper key width
padKey = (key, width) ->
	len = Math.max(0, width - "#{key}".length)
	Array(len + 1).join('0') + key

# Calculate the chucksum digit of a 7-digit pin (pair of keys)
calcChecksum = (pin) ->
	accum = 0
	while pin > 0
		accum += 3 * (pin % 10)
		pin = parseInt(pin / 10)
		accum += pin % 10
		pin = parseInt(pin / 10)
	return (10 - accum % 10) % 10

# Sequentially exhaust every key of a given length, klen
enumKeys = (klen) ->
	max = Math.pow(10, klen)
	padKey("#{i}", klen) for i in [0...max]

class WPSPinCollection
	# Takes an array of explicit keys and calculates values whenever possible
	# instead of storing all 11,000 as reaver does.
	constructor: (explicits) ->
		@keys = { '1': [], '2': [] }
		# Can be used to add keys post initialization
		@keys.add = (key) =>
			if key.length in [7,8]
				@keys[1].push key[0..3]
				@keys[2].push key[4..6]
			if key.length is 4
				@keys[1].push key
			if key.length is 3
				@keys[2].push key
		# Add the explicitly defined keys passed to us
		explicits ?= REAVER_DEF_KEYS
		(@keys.add k) for k in explicits

	# Calculate the key at a certain index
	keyAt: (set, kindex, pad=true) ->
		keys = @keys[set]
		if kindex >= keys.length
			key = kindex - keys.length
			for k in keys
				if Number(k) < (kindex - 1) then key++
		else 
			key = keys[kindex] ? '0000'
		if pad then padKey(key, 5 - set)
		else key 

	# Get / calculate the pin at provided indices
	get: (ki1, ki2) ->
		p1 = "#{@keyAt(1, ki1)}"
		p2 = "#{@keyAt(2, ki2)}"
		cs = calcChecksum Number(p1 + p2)
		return "#{p1}#{p2}#{cs}"

	# Builds an array of all possible keys in .wpc file format used for session storage, ie:
	# [4-digit explicits, remaining 4-digit, 3-digit explicits, remaining 3-digit]
	buildEnum: () ->
		kset = { '1': enumKeys(4), '2': enumKeys(3) }
		for i in [1..2]
			removed = 0
			for k in @keys[i].slice(0).sort()
				kset[i].splice Number(k) - removed++, 1
		@keys[1].concat(kset[1], @keys[2], kset[2])

module.exports = WPSPinCollection