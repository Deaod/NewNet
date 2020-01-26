class BlueShockBeamEffectOH expands BlueShockBeamEffect;

var bool bAlreadyHidden;

simulated function Tick(float F)
{
    Super.Tick(F);
    // End:0x55
    if(!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None)
    {
        // End:0x55
        if((Level.NetMode == NM_Client))
        {
            DrawType = DT_None;
            Destroy();
            bAlreadyHidden = true;
        }
    }
    return;
}

defaultproperties
{
     bOwnerNoSee=True
}