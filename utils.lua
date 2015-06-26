table.unpack = table.unpack or unpack

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

local json = require( "cjson.safe" )

function io.readjson( path )
	local contents = io.contents( path )

	if not contents then
		return
	end

	return json.decode( contents )
end

function io.writejson( path, data )
	local fd = assert( io.open( path, "w" ) )
	assert( fd:write( assert( json.encode( data ) ) ) )
	assert( fd:close() )
end

function io.contents( path )
	local fd, err = io.open( path, "r" )

	if not fd then
		return nil, err
	end

	local contents = assert( fd:read( "*all" ) )
	assert( fd:close() )

	return contents
end

function table.isempty( self )
	return #self == 0 and next( self ) == nil
end

function table.keys( self )
	local keys = { }
	for k in pairs( self ) do
		table.insert( keys, k )
	end
	return keys
end

function table.concatkeys( self, sep )
	local keys = table.keys( self )
	table.sort( keys )
	return table.concat( keys, sep )
end

function string.trim( self )
	return self:match( "^%s*(.-)%s*$" )
end
