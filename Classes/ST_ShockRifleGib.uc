class ST_ShockRifleGib extends ST_ShockRifle config(UltimateNewNet);

var bool EnableNoSpam;
var float FireSpeed;
var float AltFireSpeed;

var() sound 	FFireSound;

replication
{
	reliable if( Role==ROLE_Authority )
		EnableNoSpam, FireSpeed, AltFireSpeed;
}

function PostBeginPlay() 
{
	super.PostBeginPlay();
	EnableNoSpam = class'ComboMut'.Default.EnableNoSpam;
	FireSpeed = class'ComboMut'.Default.FireSpeed;
	AltFireSpeed = class'ComboMut'.Default.AltFireSpeed;
}

simulated function PlayFiring()
{
	if(EnableNoSpam)
	{
	LoopAnim('Fire1',FireSpeed * FireAdjust,0.05);
	}
	else
	LoopAnim('Fire1', 0.30 + 0.30 * FireAdjust,0.05);

	if(TeamShockEffects)
	{
		PlayOwnedSound(FFireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	}
	else
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
}

simulated function PlayAltFiring()
{
	if(EnableNoSpam)
	{
	LoopAnim('Fire2',AltFireSpeed * FireAdjust,0.05);
	}
	else
	LoopAnim('Fire2',0.4 + 0.4 * FireAdjust,0.05);
	PlayOwnedSound(AltFireSound, SLOT_None,Pawn(Owner).SoundDampening*4.0);
}

defaultproperties
{
     FFireSound=Sound'SSSound'
     DeathMessage="%k gibbed %o with the %w."
     PickupMessage="You got the ComboGib Rifle."
     ItemName="ComboGib Rifle"
}
