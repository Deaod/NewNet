class NewNetCG extends Arena config(UN);

var bool bInitialized, postInit;
var config bool EnableNoSpam;
var config bool bNoSelfDamage, bNoSelfBoost, bNoTeamBoost;
var config float FireRateScale;
var config float MinSecBetweenBalls;
var config int MaxShockBalls;
var config byte AntiSpamMethod;

replication
{
	reliable if( Role==ROLE_Authority )
		bNoSelfDamage, bNoSelfBoost, bNoTeamBoost;
}

function PreBeginPlay()
{
  if (bInitialized)
		return;
		
	bInitialized = True;
	bNoTeamBoost = bNoTeamBoost;
	SaveConfig();
	Super.PreBeginPlay();
	
  Log("NewNet ComboInsta loaded.");
}

function PostBeginPlay()
{
	local Inventory AUX;

	if (postInit)
		return;
		
	Enable('Tick');
	postInit = True;
	
	Level.Game.RegisterDamageMutator(Self);
	ForEach Level.AllActors(Class'Inventory',AUX) {
		if(AUX.isA('Ammo') && !AUX.bHeldItem || AUX.isA('Weapon') && !AUX.bHeldItem) {
			AUX.Destroy();
			continue; }
	}
}

event Tick(float DeltaTime)
{
	local Ammo AUX;

	ForEach Level.AllActors(Class'Ammo',AUX)
	{
	  AUX.AmmoAmount = 50; // Max Ammo
	}
}

function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, 
				out Vector HitLocation, out Vector Momentum, name DamageType)
{
	if(Victim == None || InstigatedBy == None) return;
		
	if(ActualDamage>5000) return; //For maps that force the player to take damage itself (space in dm-hyperblast)
	
	if (InstigatedBy.IsA('TournamentPlayer') && Victim==InstigatedBy && bNoSelfDamage ||
				InstigatedBy.IsA('Bot') && Victim==InstigatedBy && bNoSelfDamage) {
		ActualDamage = 0;
		if (bNoSelfBoost) {
			Momentum = Vect(0,0,0); }
	}
	else if(InstigatedBy.IsA('TournamentPlayer') || InstigatedBy.IsA('Bot') && Victim.IsA('TournamentPlayer') || Victim.IsA('Bot')) {
		ActualDamage = 1000; //hackish instagib!
		
		if(Level.Game.bTeamGame && InstigatedBy.PlayerReplicationInfo.Team==Victim.PlayerReplicationInfo.Team && 
			TeamGamePlus(Level.Game).FriendlyFireScale==0) {
				ActualDamage = 0;
				if (bNoTeamBoost) {
					Momentum = Vect(0,0,0); }
			}
	}
	if ( NextDamageMutator != None )
       NextDamageMutator.MutatorTakeDamage(ActualDamage, Victim, InstigatedBy, 
				HitLocation, Momentum, DamageType);
}

function bool AlwaysKeep(Actor Other)
{
  local bool bTemp;

	// This allows the grappling hook to be loaded during a Shock arena.
	if (InStr(Caps(Other.Class.Name),"GRAP")>=0)
		return true;

	if (InStr(Caps(Other.Class.Name),"SHOCK")>=0)
		return true;

	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
		
  return false;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if ( Other.IsA('Pickup') && !Other.IsA('UT_Jumpboots') )
		return false;
	if ( Other.IsA('Translocator') )
		return true;
	return Super.CheckReplacement( Other, bSuperRelevant );
  return true;
}

defaultproperties
{
	WeaponName=ComboGib Rifle
	AmmoName=ShockCore
	WeaponString="ST_ShockRifleGib"
	AmmoString="ShockCore"
	DefaultWeapon=Class'ST_ShockRifleGib'
	bNoSelfDamage=True
	AntiSpamMethod=1
	FireRateScale=0.5
	MaxShockBalls=3
	MinSecBetweenBalls=0.7
}
