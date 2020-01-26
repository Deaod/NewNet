class GrapHook expands Actor;

var Pawn Owned;
var HookGlow Glow;
var class<HookGlow> GlowColor[4];
var int HookSpeed, HookKillMode;
var bool bKillMe;
var bool bArc; 

var Actor AttachActor;
var int AttachPID, OwnerPID;

var float Range;
var bool bFlagFly;

replication
{
    unreliable if (ROLE==ROLE_Authority)
    bKillMe;
}


simulated function Launch(Pawn Other, float R, int HS, bool bFly, int KillMode)
{
    HookSpeed = HS;
    Range = R;
    Owned = Other;
    bFlagFly = bFly;
    HookKillMode = KillMode;

    AttachPID=-1; // Since PID can be 0
    
    GotoState('Flying');
}

simulated function Destroyed()
{
    local pawn p;

    if (Glow != None)
    Glow.Destroy();
    
    if(AttachPID!=-1)
    {
        for (p=Level.PawnList; p!=None; p=p.NextPawn)
        if((P.IsA('PlayerPawn') && !P.IsA('Spectator') || P.IsA('Bot')) && (P.PlayerReplicationInfo.PlayerID == AttachPID || P.PlayerReplicationInfo.PlayerID == OwnerPID))
        {
            P.MenuName = ""; // Just some val we use to tell whether this player was being hooked
        }
    }
}

state Flying
{

    simulated function ZoneChange( ZoneInfo NewZone )
    {
        if (NewZone.bPainZone)
        bKillMe=True;

        if (NewZone.IsA('WarpZoneInfo'))
        bKillMe=True;
    }

    simulated function HitWall(vector HitNormal, actor HitWall )
    {
        
        if(HitWall.IsA('Pawn') && (Pawn(HitWall).PlayerReplicationInfo.Team != Owned.PlayerReplicationInfo.Team && HookKillMode!=2 || Pawn(HitWall).PlayerReplicationInfo.Team == Owned.PlayerReplicationInfo.Team && Owned.PlayerReplicationInfo.HasFlag!=none) )
        {
            AttachActor = HitWall;
            AttachPID = Pawn(HitWall).PlayerReplicationInfo.PlayerID;
            OwnerPID = Owned.PlayerReplicationInfo.PlayerID;
            
            bBlockPlayers=false; // smooth movement
            bBlockActors=false;
            if(Pawn(HitWall).PlayerReplicationInfo.Team == Owned.PlayerReplicationInfo.Team) // Loudness is annoying for so long
            SoundVolume=127; 
            
            if(Pawn(HitWall).PlayerReplicationInfo.Team != Owned.PlayerReplicationInfo.Team)
            {
                if(HookKillMode==0) // For Mode == 1, sound is played in Grappling
                {
                    if(Rand(2)==1)
                    PlayerPawn(Owned).ClientPlaySound(sound'UnrealShare.Gibs.Gib2');
                    else
                    PlayerPawn(Owned).ClientPlaySound(sound'UnrealShare.Gibs.Gib3');
                }
            }
            else // I have the flag and hit my team mate
            {
                if(HitWall.IsA('PlayerPawn')) PlayerPawn(HitWall).ClientPlaySound(sound'UnrealI.Pickups.suitsnd'); // Not for bot
                PlayerPawn(Owned).ClientPlaySound(sound'UnrealI.Pickups.suitsnd');
            }
        }
        else if(HitWall.IsA('Pawn') /*|| !bFlagFly && !HitWall.IsA('Pawn') && Owned.PlayerReplicationInfo.HasFlag!=none*/) // Hit own team mate - I'm not carrying a flag (OR HookKillMode==2), Hit a wall and carrying flag but bFlagFly is not allowed so destroy hook (this will maintain the possibility to kill players with hook and attach to team mate with flag)
        bKillMe=True;
        
        AmbientSound=sound'Pull';
        GotoState('Hooked');
    }

    function Tick(float DeltaTime)
    {
        local vector LocDiff;

        if (Owned.bWarping)
        {
            bKillMe=True;
        }

        if (Range > 0)
        {
            LocDiff = Owned.Location - Location;

            if ((VSize(LocDiff) > Range))
            {
                bKillMe=True;
            }
        }

    }

    simulated function BeginState()
    {
        local rotator NewRot;

        NewRot = Owned.ViewRotation;
        SetRotation(NewRot);
        Velocity = HookSpeed*vector(NewRot);
        SetPhysics(PHYS_Projectile);
    }
}

state Hooked
{
    simulated function Tick(float DeltaTime)
    {
        if (Owned.bWarping)
        {
            bKillMe=True;
        }
        
        if(AttachActor!=none)
        { 
            if(Glow!=none) Glow.Destroy();
            Self.SetLocation(AttachActor.Location);
        }

    }


    simulated function BeginState()
    {
        local int glownum;
        local vector NewLoc;

        Velocity = vect(0,0,0);
        SetPhysics(PHYS_None);

        if ((Glow != None) || (Owned.PlayerReplicationInfo == None))
        return;


        glownum = owned.PlayerReplicationInfo.Team;

        NewLoc = Location + (1*vector(Rotation));
        Glow = spawn(GlowColor[glownum], self,,NewLoc);

    }

}

defaultproperties
{
     GlowColor(0)=Class'HookGlow'
     GlowColor(1)=Class'HookBlue'
     GlowColor(2)=Class'HookGreen'
     GlowColor(3)=Class'HookGold'
     Physics=PHYS_Projectile
     DrawType=DT_Mesh
     Mesh=LodMesh'UnrealShare.GrenadeM'
     SoundRadius=130
     SoundVolume=255
     CollisionRadius=8.000000
     CollisionHeight=3.000000
     bCollideActors=True
     bCollideWorld=True
     bBlockActors=True
     bBlockPlayers=True
     bProjTarget=True
     Mass=10.000000
}
