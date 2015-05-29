local irc = require( "irc" )
local ops = require( "ops" )
local maps = require( "maps" )
local bans = require( "bans" )

local added = { }
local MAX = 8

local function topic()
	local cmd = ops.isop( NICK ) and "TOPIC" or "PRIVMSG"

	irc.send( cmd, "%s :%d/%d", CHANNEL, #added, MAX )
end

irc.on( "PRIVMSG", function( args, nick )
	local message = args:sub( 2 )

	if message == "+" then
		if bans.isbanned( nick ) then
			irc.send( "PRIVMSG", "%s :%s: go away", CHANNEL, nick )
			
		elseif not table.find( added, nick ) then
			table.insert( added, nick )

			if #added == MAX then
				table.sort( added )
				irc.send( "PRIVMSG", "%s :join the server pls nerds: %s. callvote map %s",
					CHANNEL, table.concat( added ), maps.next() )
				added = { }

				bans.decrement()
			end

			topic()
		end

	elseif message == "-" then
		if table.find( added, nick ) then
			table.removevalue( added, nick )
			topic()
		end

	elseif message == "?" then
		table.sort( added )
		irc.send( "NOTICE", "%s :%d/%d: %s", nick, #added, MAX, table.concat( added, " " ) )
	end

end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )
	table.removevalue( added, kicked )
end )

irc.on( "NICK", function( args, nick )
	local old = args:sub( 2 )

	local i = table.find( added, old )
	if i then
		added[ i ] = nick
	end
end )

local function part_or_quit( _, nick )
	table.removevalue( added, nick )
end

irc.on( "PART", part_or_quit )
irc.on( "QUIT", part_or_quit )
