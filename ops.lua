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
		local modes = args:match( "^(%S+)" )
		local nicks_iter = args:match( "^%S+%s+(.*)$" ):gmatch( "(%S+)" )
		local lastpm

		for pm, mode in modes:gmatch( "([+-]?)([^-+])" ) do
			if pm ~= "" then
				lastpm = pm
			end

			local nick = nicks_iter()
			if not nick then
				break
			end

			if mode == "o" then
				ops[ nick ] = pm == "+" or nil
			end
		end
	end
end )

irc.on( "NICK", function( _, nick, target )
	local new = target:sub( 2 )

	if ops[ nick ] then
		ops[ nick ] = nil
		ops[ new ] = true
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
