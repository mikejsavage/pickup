local DEFAULT = 3

local irc = require( "irc" )
local ops = require( "ops" )

local bans = io.readjson( "bans.json" ) or { }

local onbans = { }

local _M = { }

local function ban( nick, target, games )
	if not ops.isop( nick ) or games > 2 ^ 16 or games < 1 then
		return
	end

	target = target:lower()
	_M.ban( target, games )

	irc.say( "%s: %s is banned for %d %s",
		nick, target, bans[ target ],
		bans[ target ] == 1 and "game" or "games" )
	log.bot( "%s banned %s for %d (now %d)",
		nick, target, games, bans[ target ] )
end

irc.command( "!ban", {
	[ "^(%S+)$" ] = function( nick, target )
		ban( nick, target, DEFAULT )
	end,

	[ "^(%S+)%s+(%d+)$" ] = function( nick, target, games )
		ban( nick, target, tonumber( games ) )
	end,
} )

irc.command( "!unban", function( nick, target )
	if not ops.isop( nick ) then
		return
	end

	target = target:lower()

	bans[ target ] = nil

	irc.say( "%s: ok", nick )
	log.bot( "%s unbanned %s", nick, target )

	io.writejson( "bans.json", bans )
end )

irc.command( "!bans", function( nick )
	local bans_list = { }
	for nick, games in pairs( bans ) do
		table.insert( bans_list, "%s(%d)" % { nick, games } )
	end
	table.sort( bans_list )

	if #bans_list == 0 then
		bans_list = { "nobody!" }
	end

	irc.say( "the following people enjoy weiners: %s",
		table.concat( bans_list, " " ) )
end )

irc.command( "sorry", function( nick )
	if bans[ nick:lower() ] == 0 then
		bans[ nick:lower() ] = nil
		io.writejson( "bans.json", bans )

		irc.say( "%s: apology accepted!", nick )
		log.bot( "%s's ban expired", nick )
	end
end )

local function rude( nick )
	bans[ nick:lower() ] = 1
	io.writejson( "bans.json", bans )

	irc.say( "%s :(", nick )
	log.bot( "%s hurt %s's feelings", nick, BOT_NICK )
end

irc.command( "no", rude )
irc.command( "fuck", rude )
irc.command( "wtf", rude )

function _M.ban( target, games )
	for _, cb in ipairs( onbans ) do
		cb( target )
	end

	target = target:lower()

	if not bans[ target ] then
		bans[ target ] = 0
	end
	bans[ target ] = bans[ target ] + games

	io.writejson( "bans.json", bans )
end

function _M.onban( cb )
	table.insert( onbans, cb )
end

function _M.checkban( nick )
	nick = nick:lower()

	if bans[ nick ] then
		if bans[ nick ] == 0 then
			irc.say( "%s: apologise", nick )
		else
			irc.say( "%s: go away", nick )
		end
	end

	return bans[ nick ] ~= nil
end

function _M.decrement()
	for nick, games in pairs( bans ) do
		bans[ nick ] = math.max( 0, games - 1 )
	end

	io.writejson( "bans.json", bans )
end

return _M
