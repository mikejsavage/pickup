local irc = require( "irc" )

local ops = { }

irc.on( "353", function( args )
	local nicks = args:match( "^[^:]*:(.*)$" )
	ops = { }

	for nick in nicks:gmatch( "(%S+)" ) do
		if nick:sub( 1, 1 ) == "@" then
			ops[ nick:sub( 2 ) ] = true
		end
	end
end )

irc.on( "MODE", function( args, nick, target )
	if target == CHANNEL then
		-- some shit
	end
end )

irc.on( "NICK", function( args, nick )
	local old = args:sub( 2 )

	if ops[ old ] then
		ops[ old ] = nil
		ops[ nick ] = true
	end
end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )

	if ops[ kicked ] then
		ops[ kicked ] = nil
	end
end )

local function part_or_quit( _, nick )
	if ops[ nick ] then
		ops[ nick ] = nil
	end
end

irc.on( "PART", part_or_quit )
irc.on( "QUIT", part_or_quit )

local _M = { }

function _M.isop( nick )
	return ops[ nick ]
end

return _M
