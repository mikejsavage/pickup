local irc = require( "irc" )
local ops = require( "ops" )
local maps = require( "maps" )
local bans = require( "bans" )

local added = { }
local MAX = 8

local function topic()
	local cmd = ops.isop( NICK ) and irc.topic or irc.say

	cmd( "%d/%d", #added, MAX )
end

local function remove( nick )
	if table.find( added, nick ) then
		table.removevalue( added, nick )
		topic()
	end
end

bans.onban( function( nick )
	remove( nick )
end )

irc.command( "+", function( nick, args )
	if args ~= "" or table.find( added, nick ) then
		return
	end

	if bans.isbanned( nick ) then
		irc.say( "%s: go away", nick )
		return
	end

	table.insert( added, nick )

	if #added == MAX then
		table.sort( added )
		irc.say( "join the server pls nerds: %s. callvote map %s",
			table.concat( added, " " ), maps.next() )
		added = { }

		bans.decrement()
	end

	topic()
end )

irc.command( "-", function( nick, args )
	if args == "" then
		remove( nick )
	end
end )

irc.command( "?", function( nick, args )
	if args == "" then
		table.sort( added )
		irc.notice( nick, "%d/%d: %s", #added, MAX, table.concat( added, " " ) )
	end
end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )
	remove( kicked )
end )

irc.on( "NICK", function( _, nick, target )
	local new = target:sub( 2 )

	local i = table.find( added, nick )
	if i then
		added[ i ] = new
	end
end )

local function part_or_quit( _, nick )
	remove( nick )
end

irc.on( "PART", part_or_quit )
irc.on( "QUIT", part_or_quit )
