local irc = require( "irc" )
local ops = require( "ops" )
local game = require( "game" )

local bans = io.readjson( "bans.json" ) or { }

local DEFAULT = 3

local function ban( nick, target, games )
	if not ops.isop( nick ) or games > 2 ^ 16 then
		return
	end

	game.remove( target )

	target = target:lower()

	if not bans[ target ] then
		bans[ target ] = 0
	end
	bans[ target ] = bans[ target ] + games

	irc.say( "%s: %s is banned for %d %s",
		nick, target, bans[ target ],
		bans[ target ] == 1 and "game" or "games" )

	io.writejson( "bans.json", bans )
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

	bans[ target:lower() ] = nil
	irc.say( "%s: ok", nick )

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
