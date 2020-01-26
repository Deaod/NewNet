class ST_sgUT_Eightball extends ST_UT_Eightball;

state NN_FireRockets
{
	simulated function bool ClientFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceFire = true;
			ServerForceFire(true);
		}
	}
	simulated function bool ClientAltFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceAltFire = true;
			ServerForceAltFire(true);
		}
	}

	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function bool SplashJump()
	{
		return false;
	}

	simulated function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets, ProjIndex;
		local bool bMultiRockets;
		local ST_sgUT_SeekingRocket s;
		local ST_sgRocketMk2 r;
		local ST_UT_Grenade g;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}

		PawnOwner = Pawn(Owner);
		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		yModInit();
		
		ServerFireRockets(bbP.zzNN_ProjIndex, bFireLoad, RocketsLoaded, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI, bAlwaysInstant || bbP.bInstantRocket);
		
		R1 = NN_GetFRV();
		
		PawnOwner.PlayRecoil(FiringSpeed);
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );

		GetAxes(GV,X,Y,Z);
		StartLoc = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;

		if ( bFireLoad ) 		
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		else 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
			
		if ( PlayerOwner != None )
			AdjustedAim = GV;
		
		PlayRFiring(RocketsLoaded-1);		
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			NN_LockedTarget = None;
			bLockedOn = false;
		}
		else if ( NN_LockedTarget == None )
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		
		//bbP.ClientMessage("Client ("$(Level.NetMode==NM_Client)$"):"@RocketsLoaded);
		While ( RocketsLoaded > 0 )
		{
			R2 = NN_GetFRV();
			R3 = NN_GetFRV();
			R4 = NN_GetFRV();
			R5 = NN_GetFRV();
			R6 = NN_GetFRV();
			R7 = NN_GetFRV();
			
			if ( bMultiRockets )
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				
				if ( NN_LockedTarget != None )
				{
					s = Spawn( class 'ST_sgUT_SeekingRocket',Owner, '', FireLocation,FireRot);
					s.Seeking = NN_LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);
					ProjIndex = bbP.xxNN_AddProj(s);
					s.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(S, class'UT_SeekingRocket', FireLocation, S.Velocity, S.Acceleration, FireRot,, NN_LockedTarget);
				}
				else 
				{
					r = Spawn( class'ST_sgRocketMk2',Owner, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);
					ProjIndex = bbP.xxNN_AddProj(r);
					r.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(R, class'RocketMk2', FireLocation, R.Velocity, R.Acceleration, FireRot);
				}
			}
			else 
			{
				g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation, AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
				ProjIndex = bbP.xxNN_AddProj(g);
				g.zzNN_ProjIndex = ProjIndex;
                bbP.xxClientDemoFix(G, class'UT_Grenade', FireLocation, G.Velocity, G.Acceleration, G.Rotation);
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
		bRotated = false;
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( !bRotated && (AmmoType.AmmoAmount > 0) ) 
		{	
			PlayLoading(1.5,0);
			RocketsLoaded = 1;
			bRotated = true;
			return;
		}
		NN_Finish();
	}
}

state FireRockets
{
	function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local ST_sgRocketMk2 r;
		local ST_sgUT_SeekingRocket s;
		local ST_UT_Grenade g;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets;
		local bool bMultiRockets;
		local bbPlayer bbP;
		local NN_sgrocketmk2OwnerHidden NNR;
		local NN_sgut_SeekingRocketOwnerHidden NNS;
		local NN_ut_GrenadeOwnerHidden NNG;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		
		bbP = bbPlayer(Owner);
		R1 = GetFRV();

		PawnOwner = Pawn(Owner);
		if ( PawnOwner == None )
			return;
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );
			
		if (bbP == None || !bNewNet)
		{
			GetAxes(PawnOwner.ViewRotation,X,Y,Z);
			StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				StartLoc = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}

		if ( bFireLoad ) 		
		{
			bbPlayer(Owner).xxAddFired(22);
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		}
		else 
		{
			bbPlayer(Owner).xxAddFired(23);
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
		}
			
		if (bbP == None || !bNewNet)
			AdjustedAim = Pawn(Owner).ViewRotation;
		else
			AdjustedAim = bbP.zzNN_ViewRot;
		
		if (!bNewNet)
			PawnOwner.PlayRecoil(FiringSpeed);
		PlayRFiring(RocketsLoaded-1);
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			LockedTarget = None;
			bLockedOn = false;
		}
		else if ( LockedTarget != None )
		{
			BestTarget = Pawn(CheckTarget());
			if ( (LockedTarget!=None) && (LockedTarget != BestTarget) ) 
			{
				LockedTarget = None;
				bLockedOn=False;
			}
		}
		else 
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		
		//bbP.ClientMessage("Server ("$(Level.NetMode!=NM_Client)$"):"@RocketsLoaded);
		While ( RocketsLoaded > 0 )
		{
			R2 = GetFRV();
			R3 = GetFRV();
			R4 = GetFRV();
			R5 = GetFRV();
			R6 = GetFRV();
			R7 = GetFRV();
			
			if ( bMultiRockets ) {
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			} else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				if ( LockedTarget != None )
				{
					if (bNewNet)
					{
						s = Spawn( class 'NN_sgut_SeekingRocketOwnerHidden',Owner, '', FireLocation,FireRot);
						NNS = NN_sgut_SeekingRocketOwnerHidden(s);
						//NNS.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNS);
					}
					else
						s = Spawn( class 'ST_sgUT_SeekingRocket',, '', FireLocation,FireRot);
					s.Seeking = LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);			
				}
				else 
				{
					if (bNewNet)
					{
						r = Spawn( class'NN_sgrocketmk2OwnerHidden',Owner, '', FireLocation,FireRot);
						NNR = NN_sgrocketmk2OwnerHidden(r);
						NNR.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNR.zzNN_ProjIndex = bbP.xxNN_AddProj(NNR);
					}
					else
						r = Spawn( class'ST_sgRocketMk2',, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);			
				}
			}
			else 
			{
				if (bNewNet)
				{
					g = Spawn( class 'NN_ut_GrenadeOwnerHidden',Owner, '', FireLocation,AdjustedAim);
					NNG = NN_ut_GrenadeOwnerHidden(g);
					//NNG.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
					if (bbP != None)
						NNG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNG);
				}
				else
					g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation,AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
		bRotated = false;
	}
}
