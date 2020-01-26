class UltimateNN_PRI extends BotReplicationInfo;

var bool bDamageIndicator;
var bool bMinigunTraceEffects;
var bool bFWS;
var bool bTeamColorShockBeams;
var bool bSniperTrace;
var byte SniperScopeStyle;
var bool bTeamTranslocators;

replication
{
	reliable if ( Role == ROLE_Authority )
		bDamageIndicator,
		bMinigunTraceEffects,
		bFWS,
		bTeamColorShockBeams,
		bSniperTrace,
		SniperScopeStyle,
		bTeamTranslocators;
}

function PostBeginPlay()
{
	if(Owner.IsA('Bot'))
	{
		bIsABot = True;
	}
	else
	{
		bIsABot = False;
	}
}

defaultproperties
{
	bDamageIndicator=True
	bMinigunTraceEffects=True
	bFWS=True
	bTeamColorShockBeams=True
	bSniperTrace=True
	SniperScopeStyle=1
	bTeamTranslocators=True

	bIsABot=False
}