local cqueues = require( "cqueues" )
local socket = require( "cqueues.socket" )

local _M = { }

local con
local subs = { }

local function publish( cmd, args, nick, target )
	if not subs[ cmd ] then
		return
	end

	for _, cb in ipairs( subs[ cmd ] ) do
		cb( args, nick, target )
	end
end

function _M.on( cmd, cb )
	subs[ cmd ] = subs[ cmd ] or { }
	table.insert( subs[ cmd ], cb )
end

function _M.send( cmd, form, ... )
	local full = cmd .. " " .. form:format( ... )
	con:write( full .. "\r\n\r\n" )
	log.traffic( "OUT %s", full )
end

function _M.connect()
	loop:wrap( function()
		con = socket.connect( HOST, PORT )
		log.traffic( "socket.connect( %s, %s )", HOST, PORT )

		con:write( "USER " .. NICK .. " " .. " " .. NICK .. " " ..  NICK .. " " .. ":" .. NICK .. "\r\n\r\n" )
		con:write( "NICK " .. NICK .. "\r\n\r\n" )

		for line in con:lines() do
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

		os.exit( 0 )
	end )
end

_M.on( "PING", function( args )
	_M.send( "PONG", args )
end )

return _M
