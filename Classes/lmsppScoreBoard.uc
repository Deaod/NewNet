class lmsppScoreBoard extends LMSScoreBoard;
var string KillsString;
var string EffString;

function DrawCategoryHeaders(Canvas Canvas)
{
    local float Offset, XL, YL;

    Offset = Canvas.CurY;
    Canvas.DrawColor = WhiteColor;

    Canvas.StrLen(PlayerString, XL, YL);
    Canvas.SetPos((Canvas.ClipX / 8)*2 - XL/2, Offset);
    Canvas.DrawText(PlayerString);

	//lives string
    Canvas.StrLen(FragsString, XL, YL);
    Canvas.SetPos((Canvas.ClipX / 8)*5 - XL/2, Offset);
    Canvas.DrawText(FragsString);
	
	//kills string
	Canvas.StrLen(KillsString, XL, YL);
    Canvas.SetPos((Canvas.ClipX / 8)*6 - XL/2, Offset);
    Canvas.DrawText(KillsString);
}

function DrawNameAndPing(Canvas Canvas, PlayerReplicationInfo PRI, float XOffset, float YOffset, bool bCompressed)
{
    local float XL, YL, XL2, YL2, XL3, YL3;
    local Font CanvasFont;
	local int Kills;
	local int Eff;
	local int Time;
	local PlayerPawn PlayerOwner;
	local KillCountLMSPRI MPRI;
	
	PlayerOwner = PlayerPawn(Owner);

	foreach PRI.ChildActors(Class'KillCountLMSPRI',MPRI){
		Kills=MPRI.KillCounter;
	}

	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);

    // Draw Name
    if ( PRI.bAdmin )
        Canvas.DrawColor = WhiteColor;
    else if (PRI.PlayerName == Pawn(Owner).PlayerReplicationInfo.PlayerName)
        Canvas.DrawColor = GoldColor;
    else 
        Canvas.DrawColor = CyanColor;
    Canvas.SetPos((Canvas.ClipX / 8) * 1.5, YOffset);
    Canvas.DrawText(PRI.PlayerName, False);

    Canvas.StrLen( "0000", XL, YL );

    // Draw Score
    if ( PRI.Score < 1 )
        Canvas.DrawColor = LightCyanColor;
    else
        Canvas.DrawColor = GoldColor;
		
	//Lives
    Canvas.StrLen( int(PRI.Score), XL2, YL );
    Canvas.SetPos( (Canvas.ClipX / 8) * 5 + XL/2 - XL2, YOffset );
    Canvas.DrawText( int(PRI.Score), false );
	
	//Kills
	Canvas.StrLen( Kills, XL2, YL );
    Canvas.SetPos( (Canvas.ClipX / 8) * 6 + XL/2 - XL2, YOffset );
    Canvas.DrawText( Kills, false );
	
	Eff=int(( Kills / ( Kills + PRI.Deaths ) ) * 100);

    if (Level.NetMode != NM_Standalone)
    {
        Canvas.DrawColor = WhiteColor;
        Canvas.Font = MyFonts.GetSmallestFont(Canvas.ClipX);

        // Draw Time
        Time = Max(1, (Level.TimeSeconds + PlayerOwner.PlayerReplicationInfo.StartTime - PRI.StartTime)/60);
        Canvas.TextSize( TimeString$": 999", XL3, YL3 );
        Canvas.SetPos( Canvas.ClipX * 0.75 + XL, YOffset );
        Canvas.DrawText( TimeString$":"@Time, false );

        // Draw Eff
        Canvas.TextSize( EffString$": 999", XL2, YL2 );
        Canvas.SetPos( Canvas.ClipX * 0.75 + XL, YOffset + 0.5 * YL );
        Canvas.DrawText( EffString$": "@Eff@"%", false );

        XL3 = FMax(XL3, XL2);
        // Draw Ping
        Canvas.SetPos( Canvas.ClipX * 0.75 + XL + XL3 + 16, YOffset );
        Canvas.DrawText( PingString$":"@PRI.Ping, false );
    }
}

function DrawTrailer( canvas Canvas )
{
    local int Hours, Minutes, Seconds;
    local float XL, YL;
    local PlayerPawn PlayerOwner;

    Canvas.bCenter = true;
    Canvas.StrLen("Test", XL, YL);
    Canvas.DrawColor = WhiteColor;
    PlayerOwner = PlayerPawn(Owner);
    Canvas.SetPos(0, Canvas.ClipY - 2 * YL);
    if ( (Level.NetMode == NM_Standalone) && Level.Game.IsA('DeathMatchPlus') )
    {
        if ( DeathMatchPlus(Level.Game).bRatedGame )
            Canvas.DrawText(DeathMatchPlus(Level.Game).RatedGameLadderObj.SkillText@PlayerOwner.GameReplicationInfo.GameName@MapTitle@MapTitleQuote$Level.Title$MapTitleQuote, true);
        else if ( DeathMatchPlus(Level.Game).bNoviceMode ) 
            Canvas.DrawText(class'ChallengeBotInfo'.default.Skills[Level.Game.Difficulty]@PlayerOwner.GameReplicationInfo.GameName@MapTitle@MapTitleQuote$Level.Title$MapTitleQuote, true);
        else  
            Canvas.DrawText(class'ChallengeBotInfo'.default.Skills[Level.Game.Difficulty + 4]@PlayerOwner.GameReplicationInfo.GameName@MapTitle@MapTitleQuote$Level.Title$MapTitleQuote, true);
    }
    else
        Canvas.DrawText(PlayerOwner.GameReplicationInfo.GameName@MapTitle@Level.Title, true);

    Canvas.SetPos(0, Canvas.ClipY - YL);
    if ( bTimeDown || (PlayerOwner.GameReplicationInfo.RemainingTime > 0) )
    {
        bTimeDown = true;
        if ( PlayerOwner.GameReplicationInfo.RemainingTime <= 0 )
            Canvas.DrawText(RemainingTime@"00:00", true);
        else
        {
            Minutes = PlayerOwner.GameReplicationInfo.RemainingTime/60;
            Seconds = PlayerOwner.GameReplicationInfo.RemainingTime % 60;
            Canvas.DrawText(RemainingTime@TwoDigitString(Minutes)$":"$TwoDigitString(Seconds), true);
        }
    }
    else
    {
        Seconds = PlayerOwner.GameReplicationInfo.ElapsedTime;
        Minutes = Seconds / 60;
        Hours   = Minutes / 60;
        Seconds = Seconds - (Minutes * 60);
        Minutes = Minutes - (Hours * 60);
        Canvas.DrawText(ElapsedTime@TwoDigitString(Hours)$":"$TwoDigitString(Minutes)$":"$TwoDigitString(Seconds), true);
    }

    if ( PlayerOwner.GameReplicationInfo.GameEndedComments != "" )
    {
        Canvas.bCenter = true;
        Canvas.StrLen("Test", XL, YL);
        Canvas.SetPos(0, Canvas.ClipY - Min(YL*6, Canvas.ClipY * 0.1));
        Canvas.DrawColor = GreenColor;
        if ( Level.NetMode == NM_Standalone )
            Canvas.DrawText(Ended@Continue, true);
        else
            Canvas.DrawText(Ended, true);
    }
    else if ( (PlayerOwner != None) && (PlayerOwner.Health <= 0) )
    {
        Canvas.bCenter = true;
        Canvas.StrLen("Test", XL, YL);
        Canvas.SetPos(0, Canvas.ClipY - Min(YL*6, Canvas.ClipY * 0.1));
        Canvas.DrawColor = GreenColor;
        Canvas.DrawText(Restart, true);
    }
    Canvas.bCenter = false;
}

defaultproperties
{
     KillsString="Kills"
	 EffString="Eff"
}