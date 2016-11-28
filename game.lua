local ev = require( "ev" )

local irc = require( "irc" )
local ops = require( "ops" )
local maps = require( "maps" )
local bans = require( "bans" )

local added = { }
local numadded = 0
local afks = { }
local lastgame = { }
local votebans = { }

local gametoken = { }

local PLAYERS = 3
local VOTES_TO_BAN = 1
local AFK_AFTER = 5 -- * 60
local AFK_WAIT_FOR = 10  --2 * 60
local AFK_HIGHLIGHTS = 4

local function update_topic()
	local cmd = ops.isop( BOT_NICK ) and irc.topic or irc.say

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

		update_topic()
	end
end

bans.onban( function( nick )
	remove( nick )
end )

local function start_game()
	local names = table.concatkeys( added, " " )

	lastgame = added
	added = { }
	numadded = 0
	votebans = { }

	gametoken.started = true
	gametoken = { }

	irc.say( "join the server pls nerds: %s. callvote map %s", names, maps.next() )
	log.bot( "game started: %s", names )

	bans.decrement()
end

local function wait_for_afks( token )
	local n = 0
	local function helper()
		if token.started or token.cancelled then
			return
		end

		n = n + 1
		if n == AFK_HIGHLIGHTS then
			for nick in pairs( afks ) do
				added[ nick ] = nil
				numadded = numadded - 1
			end
			update_topic()
			irc.say( "let's try this again without: %s", table.concatkeys( afks, " " ) )
			afks = { }

			return
		end

		irc.say( "some ppl might be afk: %s", table.concatkeys( afks, " " ) )

		local timer = ev.Timer.new( helper, AFK_WAIT_FOR / AFK_HIGHLIGHTS, 0 )
		timer:start( ev.Loop.default )
	end

	helper()
end

irc.command( "+", function( nick, args )
	if args ~= "" or added[ nick ] then
		return
	end

	if bans.checkban( nick ) then
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
			wait_for_afks( gametoken )
		end
	end

	update_topic()
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

irc.command( "!voteban", function( nick, args )
	if lastgame[ nick ] and lastgame[ args ] then
		votebans[ args ] = ( votebans[ args ] or 0 ) + 1

		if votebans[ args ] == VOTES_TO_BAN then
			bans.ban( args, 1 )

			irc.say( "banned %s for one game", args )
			log.bot( "%s was votebanned", args )

			votebans[ args ] = nil
			lastgame[ args ] = nil
		end
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
			update_topic()
		end
	end
end )

local function part_or_quit( _, nick )
	remove( nick )
end

irc.on( "PART", part_or_quit )
irc.on( "QUIT", part_or_quit )
