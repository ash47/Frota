print('\n\nINIT\n\n')

function onDataDrivenSpellStart(keys)
    -- Fire frota event
    GetFrota():FireEvent('onDataDrivenSpellStart', keys)
end
