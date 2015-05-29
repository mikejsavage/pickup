-- % = string.format
getmetatable( "" ).__mod = function( self, form )
	if type( form ) == "table" then
		local ok, err = pcall( string.format, self, unpack( form ) )

		if not ok then
			print( self )
			for _, f in ipairs( form ) do
				print( "> " .. tostring( f ) )
			end
			error( err, 2 )
		end

		return self:format( unpack( form ) )
	end

	local ok, err = pcall( string.format, self, form )

	if not ok then
		print( self )
		print( "> " .. tostring( form ) )
		assert( ok, err )
	end

	return self:format( form )
end

-- json io helpers
local json = require( "cjson.safe" )

function io.readjson( path )
	local fd = io.open( path, "r" )

	if not fd then
		return
	end

	local contents = assert( fd:read( "*all" ) )
	assert( fd:close() )

	return json.decode( contents )
end

function io.writejson( path, data )
	local fd = assert( io.open( path, "w" ) )
	assert( fd:write( assert( json.encode( data ) ) ) )
	assert( fd:close() )
end

-- table functions
function table.find( self, value )
	for i = 1, #self do
		if self[ i ] == value then
			return i
		end
	end
end

function table.removevalue( self, value )
	for i = 1, #self do
		if self[ i ] == value then
			table.remove( self, i )
			return
		end
	end
end

function table.shuffle( self )
	local n = #self

	while n > 1 do
		local k = math.random( n )
		self[ n ], self[ k ] = self[ k ], self[ n ]
		n = n - 1
	end
end

function table.split( self, n )
	local t1 = { }
	local t2 = { }

	for i = 1, n do
		table.insert( t1, self[ i ] )
	end
	for i = n + 1, #self do
		table.insert( t2, self[ i ] )
	end
	
	return t1, t2
end

-- string helpers
function string.hasprefix( self, prefix )
	return self:sub( 1, #prefix ) == prefix
end
