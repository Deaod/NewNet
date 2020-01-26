class Grappling extends TournamentWeapon config(UltimateNewNet);

#exec AUDIO IMPORT FILE="Sounds\GrapplePull.wav" NAME="Pull" 
#exec AUDIO IMPORT FILE="Sounds\GrappleEnd.wav" NAME="Reset"
#exec AUDIO IMPORT FILE="Sounds\GrappleFire.wav" NAME="Fire"

var GrapHook GrapHook;

var bool bRetract;
var bool bAttached;

var bool bHookOut;

var config int HookSpeed, HookKillMode;
var config float Range, FlySpeed, FFlySpeed;
var config float SpeedFactor;
var config bool bFlagFly, bFlagNoAttach, bFlagTeamTravel;
var config bool bDropOnfire;

var bool bAutoRetract, bPast90, bHookedEnemy, bNoResetSound;    

var vector BeginDiff;
var float BeginPrev;
var int Stuck;
var bool bTTargetOut;

replication
{
    reliable if( Role < ROLE_Authority )
    JumpRel, HookFire, HookOffhandFire;
    reliable if(Role == ROLE_Authority)
    HookSpeed, FlySpeed, FFlySpeed, Range, SpeedFactor, bFlagFly, HookKillMode, bFlagNoAttach, bFlagTeamTravel;
}

simulated function Firing( )
{
    local Vector Start, X,Y,Z;

    if (!bHookOut)
    {

        GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
        Start = Owner.Location + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;
        GrapHook = Spawn(class'GrapHook',Owner,,Start);
        if (GrapHook != None)
        {
            GrapHook.Launch(Pawn(Owner), Range, HookSpeed, bFlagFly, HookKillMode);
            bRetract=False;
            if ((ROLE==ROLE_Authority) || (Level.NetMode == NM_Standalone))
            bHookOut=True;
            settimer(0.1,true);     
            Spawn(class'FireSnd',Owner,,Owner.Location); 		
            bNoResetSound=false; // Called too early in DestroyHook() so we do it here
        }

    }
    else {
        if ((GrapHook.IsInState('Hooked')) && !bRetract)
        {
            bRetract=True;
            Pawn(Owner).bCanFly=True;
            if (bAttached)
            bAttached=False;
        }
        else if (GrapHook.IsInState('Flying'))
        {
            GrapHook.bArc=True;
        }
    }

}

simulated function AltFiring()
{

    if (bRetract)
    {
        Pawn(Owner).bCanFly=False;
        if (Pawn(Owner).HeadRegion.Zone.bWaterZone && (Owner.Physics == PHYS_Flying))
        Owner.SetPhysics(PHYS_Swimming);
    }

    if (bHookOut)
    {
        if ((ROLE==Role_Authority) || (Level.NetMode == NM_Standalone))
        DestroyHook();
        return;
    }

    if (bAttached) {
        Pawn(Owner).bCanFly=False;
        if (Pawn(Owner).HeadRegion.Zone.bWaterZone == True)
        Owner.SetPhysics(PHYS_Swimming);
        else
        Owner.SetPhysics(PHYS_Falling);
        bAttached=False;
        PlayerPawn(Owner).ClientPlaySound( sound'Reset', true );
        return;
    }

    bAutoRetract=True;
    Firing();

}

simulated function PlayIdleAnim()
{
	LoopAnim('Idle', 0.4);
}

simulated function PlayThrownAnim()
{
	PlayAnim('Thrown', 1.2,0.1);
}

function Tick(float DeltaTime)
{
    local vector LocNow, LocDiff;
    local vector NewVel, x,y,z;
    local rotator VelRot, HookRot;
    local float OwnerSpeed;
    local float Diff, Now, Begin, BeginNow;

    if (bHookOut) {
        
        if (GrapHook.bKillMe)
        {
            DestroyHook();
            return;
        }
        
        if(!bFlagFly && Pawn(Owner).PlayerReplicationInfo.HasFlag != None  && !GrapHook.IsInState('Flying') && Pawn(GrapHook.AttachActor)==none) // Stop flying with flag exploit (don't drop flag until hook is hooked otherwise we can't attach to team mate!)
        {
        CTFFlag(Pawn(Owner).PlayerReplicationInfo.HasFlag).Drop(vect(0,0,0));
        PlayerPawn(Owner).ClientPlaySound(sound'UnrealShare.General.Chunkhit1');
        }
        
        if(GrapHook.IsInState('Flying'))
        BeginDiff=GrapHook.Location - Owner.Location;

        if (GrapHook.IsInState('Hooked'))
        {

            LocDiff = GrapHook.Location - Owner.Location;
            Diff = abs(VSize(LocDiff));
            
            if(GrapHook!=none && GrapHook.AttachActor!=none)
            {
                
                if(Pawn(GrapHook.AttachActor).health > 0) // Fuck it, we will use UT's (faulty) DeathMessage :-/
                {
                    if(Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team)
                    {
                    if(HookKillMode==0) // Attach to player
                    Pawn(GrapHook.AttachActor).TakeDamage(1, Pawn(Owner), Pawn(GrapHook.AttachActor).Location, vect(0,0,0), MyDamageType);
                    else if(HookKillMode==1) // Take health
                    Pawn(GrapHook.AttachActor).TakeDamage(20, Pawn(Owner), Pawn(GrapHook.AttachActor).Location, vect(0,0,0), MyDamageType);
                    }
                    if(HookKillMode==0) Owner.SetPhysics(PHYS_None);                    
                }
                if(Pawn(GrapHook.AttachActor).health < 1 || Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team && Pawn(Owner).PlayerReplicationInfo.HasFlag==none || HookKillMode==1 && Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team || !bFlagTeamTravel && Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team) // died, No longer carrying flag: unhook!, KillMode==2 so unhook immediately, teamtravel disabled
                {
                    //if(Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team)
                    //Pawn(GrapHook.AttachActor).GibbedBy(Self); // it's either this or using a SpecialDamageString (since player doesnt need to have GrapHook selected to make the kill -> normal DeathMessage would be incorrect). Even though SpeicalDamage is a 'DeathMessage', its broadcast as WHITE text :(. Also tried custom ClientMessages with Type='DeathMessage'. Same result. According to source it should use REDSayMsgPlus to broadcast them, but doesn't..
                    if(Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team && Pawn(Owner).PlayerReplicationInfo.HasFlag==none)
                    bNoResetSound=true; // Otherwise reset sound interferes with capture sound
                    if(HookKillMode==1 && Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team)
                    {
                    // Play gibsound here, since GrapHook is destroyed immediately
                    if(Rand(2)==1)
                    PlayerPawn(Owner).ClientPlaySound(sound'UnrealShare.Gibs.Gib2',,true); 
                    else
                    PlayerPawn(Owner).ClientPlaySound(sound'UnrealShare.Gibs.Gib3',,true);
                    bNoResetSound=true; // Must mute reset sound or gib sound won't be heard :/
                    }
                    GrapHook.AttachActor=none;
                    bRetract=true;
                    bAttached=False; 
                    Owner.SetPhysics(PHYS_Walking);
                    AltFiring();
                    DestroyHook();
                    if(HookKillMode==1) return; // code below not relevant for this KillMode
                }
                
                if(GrapHook!=none && GrapHook.AttachActor!=none && !bHookedEnemy && Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team && Pawn(Owner).PlayerReplicationInfo.HasFlag!=none && bFlagTeamTravel) // Shake view of team mate when flag carrier is about to attach
                Pawn(GrapHook.AttachActor).ShakeView(1.0,1000,1000);

                if(GrapHook!=none && GrapHook.AttachActor!=none && (Diff <= 150 || bHookedEnemy))
                {               
                    if(!bHookedEnemy)
                    {
                        bHookedEnemy=true;
                        //GrapHook.SetRotation(HookRot);
                        Owner.SetCollision(true,false,false); // Prevent sticky player from telefragging other players due to SetLocation()
                        
                        if(Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team != Pawn(Owner).PlayerReplicationInfo.Team) // Only if we want to do damage (aka change damage properties... not when we are hooked to someone from our own team ;))
                        {
                        Pawn(GrapHook.AttachActor).MenuName = "hooked"; // To identify player in MutatorTakeDamage()
                        Pawn(Owner).MenuName = "hooker";
                        }
                    }
                    HookRot = GrapHook.Rotation;
                    HookRot.Yaw = GrapHook.Rotation.Yaw-32768; // Turn 180 degrees to get correct angle
                    GetAxes(HookRot,X,Y,Z);
                    if(Pawn(GrapHook.AttachActor).PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team)
                    Pawn(Owner).SetLocation(Pawn(GrapHook.AttachActor).Location+65*X+Y+10*Z);
                    else // HookKillMode 0 needs to be a bit further away
                    Pawn(Owner).SetLocation(Pawn(GrapHook.AttachActor).Location+80*X+Y+10*Z);
                }
            }

            if (Diff < 50 && !bAttached)
            {
                bRetract=False;
                
                if (Owner.Physics != PHYS_Walking)
                {
                    bAttached=True;
                    Owner.SetPhysics(PHYS_None);
                    Owner.Velocity = vect(0,0,0);
                    Pawn(Owner).bCanFly=True;
                }
                if(GrapHook!=none && GrapHook.AttachActor==none) DestroyHook();
            }
            if(GrapHook!=none && Owner!=none){
                LocNow = GrapHook.Location - Owner.Location;
                Now = abs(VSize(LocNow));
                Begin = abs(VSize(BeginDiff));
                BeginNow = Now/Begin;
                if(GrapHook.AttachActor==none && BeginPrev!=0 && BeginPrev / BeginNow < 1) 
                Stuck++;
                if(Stuck==30) AltFiring(); // Unhook when stuck
                BeginPrev = BeginNow;
                if(BeginNow<=1) // ignore jump release at start
                { 
                    if(Pawn(Owner).PlayerReplicationInfo.HasFlag == None) // Stop msg overlapping
                    PlayerPawn(Owner).ReceiveLocalizedMessage(class'Msg');
                    else
                    PlayerPawn(Owner).ReceiveLocalizedMessage(class'FlagMsg');
                    bPast90=true; 
                }
            }

            if ((Range > 0) && (Diff > Range))
            {
                if (Diff > (Range + 1000))
                {
                    AltFiring();
                }
                else {
                    VelRot = rotator(Owner.Velocity);
                    OwnerSpeed = VSize(Owner.Velocity);
                    Owner.Velocity = -1*OwnerSpeed*vector(VelRot);
                    if (Owner.Physics == PHYS_Walking)
                    Owner.SetPhysics(PHYS_Falling);
                }
            }

            if ((bAutoRetract) || (bRetract))
            {
                
                if (bAutoRetract)
                {
                    bAutoRetract=False;
                    bRetract=True;
                }

                if (Pawn(Owner).HeadRegion.Zone.bWaterZone)
                Owner.SetPhysics(PHYS_Swimming);
                else
                Owner.SetPhysics(PHYS_Falling);
                
                if (Pawn(Owner).HeadRegion.Zone.bWaterZone)
                NewVel = Pawn(Owner).WaterSpeed*SpeedFactor*vector(rotator(LocDiff));
                else
                {
                    if(Pawn(Owner).PlayerReplicationInfo.HasFlag==none)
                    NewVel = Pawn(Owner).GroundSpeed*SpeedFactor*vector(rotator(LocDiff))*FlySpeed;
                    else
                    NewVel = Pawn(Owner).GroundSpeed*SpeedFactor*vector(rotator(LocDiff))*FFlySpeed;
                }

                Pawn(Owner).Velocity = NewVel;
            }
        }
    }
}

function Timer()
{
    if (bAttached) 
    {
        if ( Pawn(Owner).weapon.IsInState('NormalFire') && bDropOnFire )
            JumpRel();

        if ( Pawn(Owner).weapon.IsInState('AltFiring') && bDropOnFire )
            JumpRel();

        if(Pawn(Owner).PlayerReplicationInfo.HasFlag == None) 
        PlayerPawn(Owner).ReceiveLocalizedMessage(class'Msg');
        else
        {
        if(bFlagNoAttach && (GrapHook==none || GrapHook.AttachActor==none)) AltFiring(); // Flag carrier cannot stay attached to wall
        PlayerPawn(Owner).ReceiveLocalizedMessage(class'FlagMsg');
        }
    }
}


function setHand(float Hand)
{

    if ( Hand != 2 )
    {
        if ( Hand == 0 )
        Hand = 1;
        else
        Hand *= -1;

        if ( Hand == -1 )
        Mesh = mesh(DynamicLoadObject("Botpack.TranslocR", class'Mesh'));
        else
        Mesh = mesh'Botpack.Transloc';
    }
    Super.SetHand(Hand);
}

function SetSwitchPriority(pawn Other)
{
    AutoSwitchPriority = 0;
    
}

simulated function bool ClientFire( float Value )
{
}

simulated function bool ClientAltFire( float Value )
{

}

function Fire( float Value )
{
    return;
}


function AltFire( float Value )
{
    return;
}

function Destroyed()
{
    if (bAttached && (Owner.Physics == PHYS_None))
    {
        Owner.SetPhysics(PHYS_Falling);
        Pawn(Owner).bCanFly=False;
    }

    if (GrapHook != None)
    GrapHook.Destroy();
    
    
    Super.Destroyed();
}

simulated function DestroyHook()
{
    if(!bAttached && !bNoResetSound) PlayerPawn(Owner).ClientPlaySound( sound'Reset', true);
    if (bHookOut)
    {
        bHookOut=False;
        bAutoRetract=False;
        bRetract=False;
        if (GrapHook != None)
        {
            GrapHook.Destroy();
            GrapHook=None;
        }
    }
    
    Owner.SetCollision(true,true,true);
    bPast90=false;
    bHookedEnemy=false;
    BeginPrev = 0;
    Stuck = 0;
}

exec function JumpRel()
{
    if(bAttached || bPast90){ if(GrapHook!=none && GrapHook.AttachActor!=none){ bAttached=False; Owner.SetPhysics(PHYS_Walking); } bRetract=true; AltFiring(); }
}

exec function HookFire()
{
    if(PlayerPawn(Owner).Weapon!=none && PlayerPawn(Owner).Weapon.IsA('Grappling') && !Level.Game.bGameEnded){
        if(GrapHook!=none && GrapHook.AttachActor!=none){ bAttached=False; Owner.SetPhysics(PHYS_Walking); }
        AltFiring();
    }
}

exec function HookOffhandFire()
{
    if(PlayerPawn(Owner).Weapon!=none && !Level.Game.bGameEnded) // Quick fix to stop feigndeath fire
    {
        if(GrapHook!=none && GrapHook.AttachActor!=none){ bAttached=False; Owner.SetPhysics(PHYS_Walking); }
        AltFiring();
    }
}

simulated function PlaySelect()
{
	bForceFire = false;
	bForceAltFire = false;
	bTTargetOut = true;
	if ( bTTargetOut )
		TweenAnim('ThrownFrame', 0.27);
	else
		PlayAnim('Select',1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.0);
	PlaySound(SelectSound, SLOT_Misc,Pawn(Owner).SoundDampening);		
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.36 );
	else
	{
		PlayAnim('Down2', 1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
	}
}

defaultproperties
{
	bDropOnfire=True
	PickupAmmoCount=1
	bCanThrow=False
	FireOffset=(X=80.000000,Y=-25.000000,Z=2.000000)
	DeathMessage="%k sliced %o with the Grappling Hook."
	AutoSwitchPriority=0
	ItemName="Grappling Hook"
	PlayerViewOffset=(X=5.000000,Y=-4.000000,Z=-7.000000)
	PlayerViewMesh=LodMesh'Botpack.Transloc'
	PickupViewMesh=LodMesh'Botpack.Trans3loc'
	ThirdPersonMesh=LodMesh'Botpack.Trans3loc'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    StatusIcon=Texture'Botpack.Icons.UseTrans'
    bNoSmooth=False
	HookSpeed=2700
	HookKillMode=1
	Range=5000.000000
	FlySpeed=1.000000
	FFlySpeed=1.000000
	SpeedFactor=2.000000
	bFlagFly=False
	bFlagNoAttach=True
	bFlagTeamTravel=False
}
