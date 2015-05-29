local irc = require( "irc" )
local ops = require( "ops" )

local pool = io.readjson( "maps.json" ) or { "wctf1", "wctf3", "wctf4", "wctf6" }
local current = 0

irc.on( "PRIVMSG", function( args, nick )
	local message = args:sub( 2 )

	if message == "!maps" then
		irc.send( "PRIVMSG", "%s :%s", CHANNEL, table.concat( pool, " " ) )
	end

	if message:find( "^!maps " ) then
		if ops.isop( nick ) then
			pool = { }
			for map in message:match( "^!maps%s+(.*)$" ):gmatch( "(%S+)" ) do
				table.insert( pool, map )
			end
			current = math.random( #pool )
			irc.send( "PRIVMSG", "%s :%s: %s", CHANNEL, nick, table.concat( pool, " " ) )
		end
	end
end )

local _M = { }

function _M.next()
	current = ( current % #pool ) + 1
	return pool[ current ]
end

return _M
