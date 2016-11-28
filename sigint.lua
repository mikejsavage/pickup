local ev = require( "ev" )
local SIGINT = 2

local function on_sigint( loop, signal )
	loop:unloop()
end

ev.Signal.new( on_sigint, SIGINT ):start( ev.Loop.default )
