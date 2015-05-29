local irc = require( "irc" )
local ops = require( "ops" )

local bans = io.readjson( "bans.json" ) or { }

irc.on( "PRIVMSG", function( args, nick )
	local message = args:sub( 2 )

	if message == "!bans" then
		local bans_list = { }
		for nick, games in pairs( bans ) do
			table.insert( bans_list, "%s(%d)" % { nick, games } )
		end
		table.sort( bans_list )

		if #bans_list == 0 then
			bans_list = { "nobody!" }
		end

		irc.send( "PRIVMSG", "%s :the following people enjoy weiners: %s", CHANNEL, table.concat( bans_list, " " ) )

	elseif message:find( "^!ban " ) and ops.isop( nick ) then
		local target, games = message:match( "^!ban%s+(%S+)%s+(%d+)$" )

		if not target then
			target = message:match( "^!ban%s+(%S+)$" )

			if target then
				games = 3
			end
		else
			games = tonumber( games )
		end

		if target and games < 2 ^ 16 then
			target = target:lower()

			if not bans[ target ] then
				bans[ target ] = 0
			end
			bans[ target ] = bans[ target ] + games

			irc.send( "PRIVMSG", "%s :%s: %s is banned for %d %s",
				CHANNEL, nick, target, bans[ target ],
				bans[ target ] == 1 and "game" or "games" )

			io.writejson( "bans.json", bans )
		
		end

	elseif message:find( "^!unban " ) and ops.isop( nick ) then
		local target = message:match( "^!unban%s+(%S+)$" )

		if target then
			bans[ target:lower() ] = nil
			irc.send( "PRIVMSG", "%s :%s: ok", CHANNEL, nick )

			io.writejson( "bans.json", bans )
		end
	end
end )

local _M = { }

function _M.isbanned( nick )
	return bans[ nick:lower() ] ~= nil
end

function _M.decrement()
	local newbans = { }

	for nick, games in pairs( bans ) do
		if games > 1 then
			newbans[ nick ] = games - 1
		end
	end

	bans = newbans
	io.writejson( "bans.json", bans )
end

return _M
