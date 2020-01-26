class GrapMut expands Mutator;

function PostBeginPlay() 
{
	Level.Game.RegisterDamageMutator( self );
}
function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, out Vector Momentum, name DamageType)
{
	if( Victim != none && Victim.Physics == PHYS_None)
	Momentum = Vect(0,0,0);
	
	if ( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );
}
function ModifyPlayer(Pawn Other)
{
	local Weapon Grap;
	if(Other.IsA('PlayerPawn') && !Other.IsA('Spectator'))
	{
	Grap=Spawn(class'Grappling', Other);
	Grap.GiveTo(Other);
	}
	
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}
function bool AlwaysKeep( Actor Other )
{
if(Other.IsA('Grappling'))
	return true;
	
if ( NextMutator != None )
        return ( NextMutator.AlwaysKeep(Other) );
    return false;
}

defaultproperties
{
}
