class lmsppServerInfo extends ServerInfo;

var string VersionCredits;

function DrawLeaderBoard( canvas C, GameReplicationInfo GRI )
{
    local float XL, YL;
    local int i;
    local TournamentGameReplicationInfo TGRI;

    C.DrawColor.R = 9;
    C.DrawColor.G = 151;
    C.DrawColor.B = 247;

    C.Font = MyFonts.GetBigFont( C.ClipX );
    C.StrLen( TopPlayersText, XL, YL );

    C.SetPos( (C.ClipX - XL) / 2, (C.ClipY / 8)*5 );
    C.DrawText( TopPlayersText, True);

    C.DrawColor.R = 0;
    C.DrawColor.G = 128;
    C.DrawColor.B = 255;

    C.Font = MyFonts.GetSmallFont( C.ClipX );

    C.SetPos( C.ClipX / 8, (C.ClipY / 8)*5 + (YL+1) );
    C.DrawText( BestNameText, True);

    C.SetPos( (C.ClipX / 8)*5, (C.ClipY / 8)*5 + (YL+1) );
    C.DrawText( BestFPHText, True);

    C.SetPos( (C.ClipX / 8)*6, (C.ClipY / 8)*5 + (YL+1) );
    C.DrawText( BestRecordSetText, True);

    C.DrawColor.R = 255;
    C.DrawColor.G = 255;
    C.DrawColor.B = 255;

    TGRI = TournamentGameReplicationInfo(GRI);
    for (i=0; i<3; i++)
    {
        C.SetPos( C.ClipX / 8, (C.ClipY / 8)*5 + (YL+1)*(i+2) );
        if ( TGRI.BestPlayers[i] != "" )
            C.DrawText( TGRI.BestPlayers[i], True);
        else
            C.DrawText( "--", True);

        C.SetPos( (C.ClipX / 8)*5, (C.ClipY / 8)*5 + (YL+1)*(i+2) );
        if ( TGRI.BestPlayers[i] != "" )
            C.DrawText( TGRI.BestFPHs[i], True);
        else
            C.DrawText( "--", True);

        C.SetPos( (C.ClipX / 8)*6, (C.ClipY / 8)*5 + (YL+1)*(i+2) );
        if ( TGRI.BestPlayers[i] != "" )
            C.DrawText( TGRI.BestRecordDate[i], True);
        else
            C.DrawText( "--", True);
    }
	
	C.StrLen(VersionCredits, XL, YL);
	C.SetPos((C.ClipX - XL)/2, C.ClipY - YL);
	C.DrawText(VersionCredits, true);
}

defaultproperties
{
	VersionCredits="[ Last Man Standing ]"
}