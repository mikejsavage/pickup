local cqueues = require( "cqueues" )

local irc = require( "irc" )
local ops = require( "ops" )
local maps = require( "maps" )
local bans = require( "bans" )

local added = { }
local numadded = 0
local afks = { }

local gametoken = { }

local PLAYERS = 8
local AFK_AFTER = 5 * 60
local AFK_WAIT_FOR = 2 * 60
local AFK_HIGHLIGHTS = 4

local function topic()
	local cmd = ops.isop( NICK ) and irc.topic or irc.say

	cmd( "%d/%d", numadded, PLAYERS )
end

local function remove( nick )
	if added[ nick ] then
		if numadded == PLAYERS then
			gametoken.cancelled = true
			gametoken = { }
		end

		added[ nick ] = nil
		numadded = numadded - 1

		topic()
	end
end

bans.onban( function( nick )
	remove( nick )
end )

local function start_game()
	local names = table.concatkeys( added, " " )

	added = { }
	numadded = 0
	votebans = { }

	gametoken.started = true
	gametoken = { }

	irc.say( "join the server pls nerds: %s. callvote map %s", names, maps.next() )
	topic()
	log.bot( "game started: %s", names )

	bans.decrement()
end

irc.command( "+", function( nick, args )
	if args ~= "" or added[ nick ] then
		return
	end

	if bans.isbanned( nick ) then
		irc.say( "%s: go away", nick )
		return
	end

	if numadded == PLAYERS then
		return
	end

	added[ nick ] = os.time()
	numadded = numadded + 1

	if numadded == PLAYERS then
		afks = { }
		local now = os.time()
		for player, lastactive in pairs( added ) do
			if now - lastactive > AFK_AFTER then
				afks[ player ] = true
			end
		end

		if table.isempty( afks ) then
			start_game()
		else
			local token = gametoken

			loop:wrap( function()
				for i = 1, AFK_HIGHLIGHTS do
					if token.started or token.cancelled then
						break
					end

					irc.say( "some ppl might be afk: %s", table.concatkeys( afks, " " ) )
					cqueues.sleep( AFK_WAIT_FOR / AFK_HIGHLIGHTS )
				end

				if not token.started then
					for nick in pairs( afks ) do
						added[ nick ] = nil
						numadded = numadded - 1
					end
					topic()
					irc.say( "let's try this again without: %s", table.concatkeys( afks, " " ) )
					afks = { }
				end
			end )
		end
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
		irc.notice( nick, "%d/%d: %s", numadded, PLAYERS, table.concatkeys( added, " " ) )
	end
end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )
	remove( kicked )
end )

irc.on( "NICK", function( _, nick, target )
	local new = target:sub( 2 )

	if added[ nick ] then
		added[ new ] = os.time()
		added[ nick ] = nil
	end
end )

irc.on( "PRIVMSG", function( _, nick )
	if added[ nick ] then
		added[ nick ] = os.time()
	end

	if afks[ nick ] then
		afks[ nick ] = nil

		if table.isempty( afks ) and numadded == PLAYERS then
			start_game()
		end
	end
end )

local function part_or_quit( _, nick )
	remove( nick )
end

irc.on( "PART", part_or_quit )
irc.on( "QUIT", part_or_quit )
