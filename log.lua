local _M = { }

local function logger( path, echo )
	local fd = assert( io.open( path, "a" ) )

	return function( format, ... )
		local now = os.date( "[%a %d %b %X] " )
		local msg = format:format( ... )

		assert( fd:write( now .. msg .. "\n" ) )
		fd:flush()
		if echo then
			print( msg )
		end
	end
end

_M.traffic = logger( "traffic.log" )
_M.error = logger( "error.log", true )

return _M
