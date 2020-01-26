//================================================================================
// WRI.
//================================================================================
class WRI extends ReplicationInfo;

var() Class<UWindowWindow> WindowClass;
var() int WinLeft;
var() int WinTop;
var() int WinWidth;
var() int WinHeight;
var() bool DestroyOnClose;
var UWindowWindow TheWindow;
var int TicksPassed;
var bool bDestroyRequested;

replication
{
     reliable if ( Role == ROLE_Authority)
          OpenWindow, CloseWindow;

     reliable if ( Role < ROLE_Authority )
          DestroyWRI;
}

event PostBeginPlay ()
{
	Super.PostBeginPlay();
	OpenIfNecessary();
}

simulated event PostNetBeginPlay ()
{
	PostBeginPlay();
	OpenIfNecessary();
}

simulated function OpenIfNecessary ()
{
	local PlayerPawn P;

	if ( Owner != None )
	{
		P=PlayerPawn(Owner);
		if ( (P != None) && (P.Player != None) && (P.Player.Console != None) )
		{
			OpenWindow();
		}
	}
}

simulated function bool OpenWindow ()
{
	local PlayerPawn P;
	local WindowConsole C;

	P=PlayerPawn(Owner);
	if ( P == None )
	{
		Log("#### -- Attempted to open a window on something other than a PlayerPawn");
		DestroyWRI();
		return False;
	}
	C=WindowConsole(P.Player.Console);
	if ( C == None )
	{
		Log("#### -- No Console");
		DestroyWRI();
		return False;
	}
	if (  !C.bCreatedRoot || (C.Root == None) )
	{
		C.CreateRootWindow(None);
	}
	C.bQuickKeyEnable=True;
	C.LaunchUWindow();
	TicksPassed=1;
	return True;
}

simulated function Tick (float DeltaTime)
{
	if ( TicksPassed != 0 )
	{
		if ( TicksPassed++  == 3 )
		{
			SetupWindow();
			TicksPassed=0;
		}
	}
	if ( DestroyOnClose && (TheWindow != None) &&  !TheWindow.bWindowVisible &&  !bDestroyRequested )
	{
		bDestroyRequested=True;
		DestroyWRI();
	}
}

simulated function bool SetupWindow ()
{
	local WindowConsole C;

	C=WindowConsole(PlayerPawn(Owner).Player.Console);
	TheWindow=C.Root.CreateWindow(WindowClass,WinLeft,WinTop,WinWidth,WinHeight);

	if(C.Root.WinWidth <= 800)
	{
		WinWidth = WinWidth - 61;
	}

	if(C.Root.WinHeight <= 600)
	{
		WinHeight = WinHeight - 42;
	}

	if ( TheWindow == None )
	{
		Log("#### -- CreateWindow Failed");
		DestroyWRI();
		return False;
	}
	if ( C.bShowConsole )
	{
		C.HideConsole();
	}
	TheWindow.bLeaveOnscreen=True;
	TheWindow.ShowWindow();
	return True;
}

simulated function CloseWindow ()
{
	local WindowConsole C;

	C=WindowConsole(PlayerPawn(Owner).Player.Console);
	C.bQuickKeyEnable=False;
	if ( TheWindow != None )
	{
		TheWindow.Close();
	}
}

function DestroyWRI ()
{
	Destroy();
}

defaultproperties
{
     DestroyOnClose=True
     bAlwaysRelevant=False
     RemoteRole=ROLE_SimulatedProxy
     NetPriority=2.000000
}
