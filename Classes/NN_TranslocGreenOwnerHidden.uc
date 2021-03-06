class NN_TranslocGreenOwnerHidden extends TranslocGreen;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	
	if ( Owner == None )
		return;
	
	if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden)
		if (Level.NetMode == NM_Client)
			Destroy();
		bAlreadyHidden = True;
	}
}

defaultproperties
{
     bOwnerNoSee=True
}
