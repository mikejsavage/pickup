local ev = require( "ev" )
local socket = require( "socket" )

local _M = { }

local loop = ev.Loop.default
local sock

local listeners = { }
local commands = { }

local function publish( cmd, args, nick, target )
	if not listeners[ cmd ] then
		return
	end

	for _, cb in ipairs( listeners[ cmd ] ) do
		cb( args, nick, target )
	end
end

function _M.on( cmd, cb )
	listeners[ cmd ] = listeners[ cmd ] or { }
	table.insert( listeners[ cmd ], cb )
end

function _M.send( form, ... )
	local full = form:format( ... )
	sock:send( full .. "\r\n\r\n" )
	log.traffic( "OUT %s", full )
end

function _M.say( form, ... )
	_M.send( "PRIVMSG %s :" .. form, CHANNEL, ... )
end

function _M.notice( nick, form, ... )
	_M.send( "NOTICE %s :" .. form, nick, ... )
end

function _M.topic( form, ... )
	_M.send( "TOPIC %s :" .. form, CHANNEL, ... )
end

function _M.command( name, callbacks )
	assert( not commands[ name ], "already a command called " .. name )

	if type( callbacks ) == "function" then
		callbacks = { [ "^.*$" ] = callbacks }
	end

	commands[ name ] = callbacks
end

local buf = ""
local function data_handler()
	local _, err, data = sock:receive( "*a" )

	if err == "closed" then
		os.exit( 1 )
	end

	if not data then
		data = _
	end

	buf = buf .. data:gsub( "\r", "" )

	while true do
		local line, len = buf:match( "^([^\n]*)\n()" )
		if not line then
			return
		end

		buf = buf:sub( len )

		log.traffic( "IN  %s", line )

		if line:sub( 1, 1 ) == ":" then
			local nick, host, cmd, target, args = line:match( "^:([^!%s]-)!?([^!%s]+)%s+(%S+)%s+(%S+)%s*(.*)$" )

			if cmd then
				publish( cmd, args, nick, target )
			else
				log.error( "Couldn't parse line: %s", line )
			end
		else
			local cmd, args = line:match( "^(%S+)%s+(.*)$" )

			if cmd then
				publish( cmd, args )
			else
				log.error( "Couldn't parse line: %s", line )
			end
		end
	end
end

function _M.connect()
	sock = socket.tcp()
	sock:settimeout( 0 )

	sock:connect( HOST, PORT )

	ev.IO.new( function( loop, watcher )
		local _, err = sock:receive( "*a" )

		if err == "connection refused" then
			os.exit( 1 )
		end


		ev.IO.new( function( loop, watcher )
			data_handler()
		end, sock:getfd(), ev.READ ):start( loop )

		ev.IO.new( function( loop, watcher )
			sock:send( "USER " .. BOT_NICK .. " " .. " " .. BOT_NICK .. " " ..  BOT_NICK .. " :" .. BOT_NICK .. "\r\n\r\n" )
			sock:send( "NICK " .. BOT_NICK .. "\r\n\r\n" )
			watcher:stop( loop )
		end, sock:getfd(), ev.WRITE ):start( loop )

		watcher:stop( loop )
	end, sock:getfd(), ev.WRITE ):start( loop )
end

_M.on( "PING", function( args )
	_M.send( "PONG %s", args )
end )

_M.on( "PRIVMSG", function( message, nick )
	message = message:sub( 2 )

	local command, args = message:match( "^(%S+)%s*(.-)%s*$" )

	if command and commands[ command ] then
		for pattern, callback in pairs( commands[ command ] ) do
			local matches = { args:match( pattern ) }

			if #matches > 0 then
				callback( nick, table.unpack( matches ) )
				break
			end
		end
	end
end )

return _M
