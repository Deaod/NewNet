class NN_WeaponLightOwnerHidden extends WeaponLight;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		LightType = LT_None;
		bAlreadyHidden = True;
	}
}

defaultproperties {
	bOwnerNoSee=True
}