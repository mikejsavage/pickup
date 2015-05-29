local irc = require( "irc" )
local ops = require( "ops" )

local pool = io.readjson( "maps.json" ) or { "wctf1", "wctf3", "wctf4", "wctf6" }
local current = 0

irc.command( "!maps", {
	[ "^$" ] = function()
		irc.say( "%s", table.concat( pool, " " ) )
	end,

	[ "^(.+)$" ] = function( nick, maps )
		if not ops.isop( nick ) then
			return
		end

		pool = { }
		for map in maps:gmatch( "(%S+)" ) do
			table.insert( pool, map )
		end
		current = math.random( #pool )

		irc.say( "%s: %s", nick, table.concat( pool, " " ) )

		io.writejson( "maps.json", pool )
	end,
} )

local _M = { }

function _M.next()
	current = ( current % #pool ) + 1
	return pool[ current ]
end

return _M
