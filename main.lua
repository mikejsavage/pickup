#! /usr/bin/lua

BOT_NICK = "PERRINABOT"
CHANNEL = "#gladiator"
HOST = "irc.quakenet.org"
PORT = 6667

require( "utils" )
require( "sigint" )

local ev = require( "ev" )

local ok, arc4 = pcall( require, "arc4random" )
if ok then
	math.random = arc4.random
else
	math.randomseed( os.time() )
end

log = require( "log" )
require( "game" )

local irc = require( "irc" )

irc.on( "MODE", function( args, nick, target )
	if target == BOT_NICK and nick == BOT_NICK and args == "+i" then
		local auth = io.contents( "auth.txt" )
		if auth then
			irc.send( "PRIVMSG Q@CServe.quakenet.org :auth %s", auth:trim() )
		end

		irc.send( "JOIN %s", CHANNEL )
	end
end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )

	if kicked == BOT_NICK then
		return os.exit( 0 )
	end
end )

irc.connect()

assert( ev.Loop.default:loop() )
