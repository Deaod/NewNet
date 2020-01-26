class SGData extends Mutator;

var Weapon ReplaceThis, ReplaceWith;
var SGSpawnNotify ReplaceSN;
var bool bApplySNReplace;

function bool IsRelevant(Actor Other, out byte bSuperRelevant)
{
	local int Result;

	Result = WeaponReplacement(Other); //0 = replace, 1 = no replace, 2 = delayed replace
	if ( Result == 1 && (NextMutator != None) ) //Do not let mutators alter delayed replacements
		Result = int(NextMutator.IsRelevant(Other, bSuperRelevant));

	return (Result > 0);
}

function Class<Weapon> MyDefaultWeapon()
{
	if ( Level.Game.DefaultWeapon == class'ImpactHammer' )
		return class'ST_ImpactHammer';
	return Level.Game.DefaultWeapon;
}

function int WeaponReplacement (Actor Other)
{
	if ( Weapon(Other) == none )
		return 1;

	if ( Other.Class == class'ImpactHammer' )
		return DoReplace(Weapon(Other),class'ST_ImpactHammer');

	else if ( Other.Class == class'ST_Translocator' )
	{
		return 0;
	}
	
	else if ( ClassIsChildOf( Other.Class, class'Enforcer') )
	{
		if ( Other.Class == class'Enforcer' )
			return DoReplace(Weapon(Other),class'ST_Enforcer');
		else if ( Other.IsA('sgEnforcer') )
			return DoReplace(Weapon(Other),class'ST_Enforcer',,true);
	}
	
	else if ( Other.Class == class'ut_biorifle' )
	{
		return DoReplace(Weapon(Other),class'ST_ut_biorifle');
	}
	
	else if ( Other.Class == class'ShockRifle' )
	{
		return DoReplace(Weapon(Other),class'ST_SiegeShockRifle');
	}

	else if ( ClassIsChildOf( Other.Class, class'PulseGun') )
	{
		if ( Other.Class == class'PulseGun' )
			return DoReplace(Weapon(Other),class'ST_PulseGun');
		else if ( Other.IsA('sgPulseGun') )
			return DoReplace(Weapon(Other),class'ST_PulseGun',,true);
	}
	
	else if ( Other.Class == class'ripper' )
	{
		return DoReplace(Weapon(Other),class'ST_ripper');
	}

	else if ( ClassIsChildOf( Other.Class, class'Minigun2') )
	{
		if ( Other.Class == class'Minigun2' )
			return DoReplace(Weapon(Other),class'ST_Minigun2');
		else if ( Other.IsA('sgMinigun') )
			return DoReplace(Weapon(Other),class'ST_Minigun2',,true);
	}
	
	else if ( Other.Class == class'UT_FlakCannon' )
	{
		return DoReplace(Weapon(Other),class'ST_UT_FlakCannon');
	}
	
	else if ( Other.Class == class'UT_Eightball' )
	{
		return DoReplace(Weapon(Other),class'ST_sgUT_Eightball');
	}
	
	else if ( Other.Class == class'SniperRifle' )
	{
		return DoReplace(Weapon(Other),class'ST_SniperRifle');
	}

	else if ( Other.IsA('AsmdPulseRifle') )
	{
		Class'ST_AsmdPulseRifle'.default.OrgClass = class<TournamentWeapon>(Other.Class);
		return DoReplace( Weapon(Other), class'ST_AsmdPulseRifle');
	}
	
	else if ( Other.IsA('ApeCannon') )
	{
		Class'ST_ApeCannon'.default.OrgClass = class<TournamentWeapon>(Other.Class);
		return DoReplace( Weapon(Other), class'ST_ApeCannon');
	}
	
	else if ( Other.IsA('HyperLeecher') )
	{
		Class'ST_HyperLeecher'.default.OrgClass = class<TournamentWeapon>(Other.Class);
		return DoReplace( Weapon(Other), class'ST_HyperLeecher');
	}
	
	else if ( Other.IsA('SiegeInstagibRifle') )
	{
		Class'ST_SiegeInstaGibRifle'.default.OrgClass = class<TournamentWeapon>(Other.Class);
		return DoReplace( Weapon(Other), class'ST_SiegeInstaGibRifle');
	}
	return 1;
}

function int DoReplace( Weapon Other, class<Weapon> NewWeapClass, optional bool bFullAmmo, optional bool bCopyAmmo)
{
	local Weapon W;

	W = Other.Spawn(NewWeapClass);
	if ( W != none )
	{
		W.SetCollisionSize( Other.CollisionRadius, Other.CollisionHeight);
		W.Tag = Other.Tag;
		W.Event = Other.Event;
		if ( Other.MyMarker != none )
		{
			W.MyMarker = Other.MyMarker;
			W.MyMarker.markedItem = W;
		}
		W.bHeldItem = Other.bHeldItem;
		W.RespawnTime = Other.RespawnTime;
		W.PickupAmmoCount = Other.PickupAmmoCount;
		if ( bCopyAmmo )
			W.AmmoName = Other.AmmoName;
		if ( bFullAmmo )
			W.PickupAmmoCount = W.AmmoName.default.MaxAmmo;
		W.bRotatingPickup = Other.bRotatingPickup;
		SetReplace( Other, W);
		return int(bApplySNReplace) * 2;
	}
	return 1;
}

event PostBeginPlay()
{
	ReplaceSN = Spawn(class'SGSpawnNotify');
	ReplaceSN.Mutator = self;
}

function SetReplace( Weapon Other, Weapon With)
{
	ReplaceThis = Other;
	ReplaceWith = With;
	if ( ReplaceThis != none && ReplaceWith != none)
		ReplaceSN.ActorClass = ReplaceThis.class;
	else
		ReplaceSN.ActorClass = class'ST_DummyWeapon';
}
