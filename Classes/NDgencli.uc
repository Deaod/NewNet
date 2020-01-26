/************************************************************
 * NDgencli
 ************************************************************/
class NDgencli extends ReplicationInfo;


var bool bEnd;
var bool bEndDone;
var PlayerPawn P;
var int MessageTimer;
var bool bNotifyKeyBind;



replication
{
     reliable if (Role == ROLE_Authority)
	         bEnd,
	         MessageTimer,
	         bNotifyKeyBind,
             SetKeyBind;
}

simulated function Tick(float DeltaTime)
{
	if(Level.Netmode == NM_DedicatedServer)
	{
		if(Level.Game.bGameEnded)
		bEnd = true;
	}
	else if(Level.Netmode != NM_DedicatedServer && P!=none && bEnd && !bEndDone)
	{
		bEndDone = true;
		P.ConsoleCommand("Mutate SmartCTF ForceStats");
	}
}

simulated function SetKeyBind(int ID, string KeyName)
{
    //Bind Grapple Hook to a key
    P.ConsoleCommand("SET INPUT " $KeyName $" HOOKOFFHANDFIRE");

    //Validate
    if (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "HOOKOFFHANDFIRE") != -1)
        P.ClientMessage("KeyBind was successful!",,true);
    else
        P.ClientMessage("KeyBind Failed! Please try again!",,true);
}

simulated function PostBeginPlay()
{
	foreach AllActors(class 'PlayerPawn', P)
	if(Viewport(P.Player) != None)
		break;

	if (P == none)
	    return;

	SetTimer(1.0,true);
}

simulated function Timer()
{
		InitializeKeys(P);
		SetTimer(MessageTimer,true);
}

simulated function InitializeKeys(PlayerPawn P)
{
	local string keyName;
	local string keyBinding;
	local int i;
	local bool bOffhand;
	for (i=0; i<255; i++)
	{
		keyName = P.ConsoleCommand("Keyname"@i);

		if ((InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "FIRE") != -1)
				&& (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "HOOKFIRE")) == -1 && (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "HOOKOFFHANDFIRE")) == -1)
		{
			keyBinding = P.ConsoleCommand("Keybinding"@keyName);
			P.ConsoleCommand("SET INPUT"@keyName@"HookFire|"$keyBinding);
		}

		if ((InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "JUMP") != -1)
				&& (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "JUMPREL")) == -1)
		{
			keyBinding = P.ConsoleCommand("Keybinding"@keyName);
			P.ConsoleCommand("SET INPUT"@keyName@"JumpRel|"$keyBinding);
		}

		if ((InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "TRANSLOCATOR") != -1)
				&& (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "GRAPPLING")) == -1)
		{
			keyBinding = P.ConsoleCommand("Keybinding"@keyName);
			P.ConsoleCommand("SET INPUT"@keyName@"getweapon Grappling|"$keyBinding);
		}

		if (InStr( Caps(P.ConsoleCommand("Keybinding"@keyName)), "HOOKOFFHANDFIRE") != -1)
		{
			bOffhand = true;
			SetTimer(0,false);
		}
	}

	if (InStr( Caps(P.ConsoleCommand("Keybinding F3")), "SHOWSTATS") == -1)
	{
		keyBinding = P.ConsoleCommand("Keybinding F3");
		P.ConsoleCommand("SET INPUT F3 Mutate SmartCTF ShowStats|"$keyBinding);
	}

	if(bNotifyKeyBind && !bOffhand)
	{
		P.ReceiveLocalizedMessage(class'MsgBind');
	}
}

defaultproperties
{
     MessageTimer=30
     bNotifyKeyBind=True
     RemoteRole=ROLE_SimulatedProxy
     NetPriority=10.000000
}
