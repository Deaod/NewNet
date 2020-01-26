class h4x_Xloc extends ST_Translocator;

#exec AUDIO IMPORT FILE="Sounds\h4xEnergize.WAV" NAME="h4xEnergize" GROUP="XLoc"

function setHand(float Hand)
{
	if ( Hand != 2 )
	{
		if ( Hand == -1 )
			Mesh = mesh(DynamicLoadObject("Botpack.TranslocR", class'Mesh'));
		else
			Mesh = mesh'Botpack.Transloc';
	}
	Super.SetHand(Hand);
}

function float RateSelf( out int bUseAltMode )
{
	return -2;
}

function BringUp()
{
	PreviousWeapon = None;
	Super.BringUp();
}

function RaiseUp(Weapon OldWeapon)
{
	if ( OldWeapon == self )
		PreviousWeapon = None;
	else
		PreviousWeapon = OldWeapon;
	Super.BringUp();
}

function float SuggestAttackStyle()
{
	local float EnemyDist;

	if ( bTTargetOut )
		return -0.6;

	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	if ( EnemyDist < 700 )
		return 1.0;
	else
		return -0.2;
}

function float SuggestDefenseStyle()
{
	if ( bTTargetOut )
		return 0;

	return -0.6;
}

function SetSwitchPriority(pawn Other)
{
	AutoSwitchPriority = 0;
}

simulated function ClientWeaponEvent(name EventType)
{
	if ( EventType == 'TouchTarget' )
		PlayIdleAnim();
}

function SpawnEffect(vector Start, vector Dest)
{
	local actor e;
	
	PlaySound(Sound'h4xEnergize', SLOT_None, Pawn(Owner).SoundDampening*3.0);
	e = Spawn(class'Energize',,,start, Owner.Rotation);
	e.Mesh = Owner.Mesh;
	e.Animframe = Owner.Animframe;
	e.Animsequence = Owner.Animsequence;
}

defaultproperties
{
    TossForce=830.00
    MaxTossForce=830.00
    WeaponDescription="Modified translocator for h4x."
    PickupMessage="You got the h4x Translocator Source Module."
    ItemName="h4x Translocator"
	bPlayTeleportEffect=False
}
