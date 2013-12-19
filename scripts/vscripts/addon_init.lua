function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...) end
        return w
    else
        return mt[name]
    end
end

require( "util" )
require( "frota" )

print("\n\nDone Loading!\n\n")
