class ST_SuperZoomShockRifle extends ST_SuperShockRifle;

simulated function PostRender( canvas Canvas )
{
	local PlayerPawn P;
	local float Scale;

	Super.PostRender(Canvas);
	P = PlayerPawn(Owner);
	if ( (P != None) && (P.DesiredFOV != P.DefaultFOV) ) 
	{
		bOwnsCrossHair = true;
		Scale = Canvas.ClipX/640;
		Canvas.SetPos(0.504 * Canvas.ClipX - 128 * Scale, 0.504 * Canvas.ClipY - 128 * Scale );
		if ( Level.bHighDetailMode )
			Canvas.Style = ERenderStyle.STY_Translucent;
		else
			Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawIcon(Texture'RReticle', Scale);
		Canvas.SetPos(0.5 * Canvas.ClipX + 64 * Scale, 0.5 * Canvas.ClipY + 96 * Scale);
		Canvas.DrawColor.R = 0;
		Canvas.DrawColor.G = 255;
		Canvas.DrawColor.B = 0;
		Scale = P.DefaultFOV/P.DesiredFOV;
		Canvas.DrawText("X"$int(Scale)$"."$int(10 * Scale - 10 * int(Scale)));
	}
	else
		bOwnsCrossHair = false;
}

function AltFire( float Value )
{
	ClientAltFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
		return false;
	GotoState('Zooming');
	PlayAltFiring();
	return true;
}

state Zooming
{
	simulated function Tick(float DeltaTime)
	{
		if ( Pawn(Owner).bAltFire == 0 )
		{
			if ( (PlayerPawn(Owner) != None) && PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).StopZoom();
			SetTimer(0.0,False);
			GoToState('Idle');
		}
	}

	simulated function BeginState()
	{
		if ( Owner.IsA('PlayerPawn') )
		{
			if ( PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).ToggleZoom();
			SetTimer(0.2,True);
		}
		else
		{
			Pawn(Owner).bFire = 1;
			Pawn(Owner).bAltFire = 0;
			Global.Fire(0);
		}
	}
}

simulated function PlayAltFiring()
{
	LoopAnim('Still');
}
