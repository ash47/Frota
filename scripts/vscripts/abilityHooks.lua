print('\n\nINIT\n\n')

function onDataDrivenSpellStart(keys)
    -- Fire frota event
    GetFrota():FireEvent('onDataDrivenSpellStart', keys)
end

function onDataDrivenChannelSucceeded(keys)
    -- Fire frota event
    GetFrota():FireEvent('onDataDrivenChannelSucceeded', keys)
end

function onDataDrivenChannelInterrupted(keys)
    -- Fire frota event
    GetFrota():FireEvent('onDataDrivenChannelInterrupted', keys)
end