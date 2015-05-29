#! /usr/bin/lua5.2

NICK = "FLAGBOT"
CHANNEL = "#ctf"
HOST = "irc.quakenet.org"
PORT = 6667

require( "utils" )

local cqueues = require( "cqueues" )
local thread = require( "cqueues.thread" )
loop = cqueues.new()

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
	if target == NICK and nick == NICK and args == "+i" then
		local password = io.contents( "password.txt" )
		if password then
			irc.send( "PRIVMSG Q@CServe.quakenet.org :auth %s %s", NICK, password:trim() )
		end

		irc.send( "JOIN %s", CHANNEL )
	end
end )

irc.on( "KICK", function( args )
	local kicked = args:match( "^(.-) :" )

	if kicked == NICK then
		return os.exit( 0 )
	end
end )

irc.connect()

assert( loop:loop() )
