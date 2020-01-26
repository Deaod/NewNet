class NN_WeaponFunctions extends Object;

static simulated function SetSwitchPriority(pawn Other, weapon Weap, name CustomName)
{
	local int i;
	local name temp, carried;

	if ( PlayerPawn(Other) != None )
	{
		for ( i=0; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++)
			if ( PlayerPawn(Other).WeaponPriority[i] == CustomName )
			{
				Weap.AutoSwitchPriority = i;
				return;
			}
		carried = CustomName;
		for ( i=Weap.AutoSwitchPriority; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++ )
		{
			if ( PlayerPawn(Other).WeaponPriority[i] == '' )
			{
				PlayerPawn(Other).WeaponPriority[i] = carried;
				return;
			}
			else if ( i<ArrayCount(PlayerPawn(Other).WeaponPriority)-1 )
			{
				temp = PlayerPawn(Other).WeaponPriority[i];
				PlayerPawn(Other).WeaponPriority[i] = carried;
				carried = temp;
			}
		}
	}		
}

static simulated function TweenDown (TournamentWeapon W)
{
	if ( W.IsAnimating() && (W.AnimSequence != 'None') && (W.GetAnimGroup(W.AnimSequence) == 'Select') )
		W.TweenAnim( W.AnimSequence, W.AnimFrame * 0.4 );
	else
		W.PlayAnim('Down', 1.5 + float(Pawn(W.Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
}

static simulated function PlaySelect (TournamentWeapon W)
{
	local bbPlayer bbP;

	if ( (W.Level.NetMode == NM_Client) && (bbP != None) && bbP.bNewNet )
	{
		if ( (enforcer(W) != None) && (W.GetStateName() == W.Class.Name) )
		{
			return;
		}
	}
	W.bForceFire = False;
	W.bForceAltFire = False;
	W.bCanClientFire = False;
	if ( !W.IsAnimating() || (W.AnimSequence != 'Select') )
		W.PlayAnim('Select',1.5 + float(Pawn(W.Owner).PlayerReplicationInfo.Ping) / 1000,0.0);
	W.Owner.PlaySound(W.SelectSound, SLOT_Misc, Pawn(W.Owner).SoundDampening);
}
