class IndiaSettings extends ReplicationInfo config(UltimateNewNetv0_6_Client);

var config bool bDamageIndicator;
var config bool bTeamShockBeams;
var config bool bSniperTraceEffects;
var config bool bFWS;
var config bool bShowLowAmmoWarning;
var config byte BeepSoundType;
var config byte SniperScopeStyle;
var config byte ChatAreaPosition;
var config bool bShowTeamMatesLocation;
var config bool bShowFlagsLocation;

defaultproperties
{
	bDamageIndicator=True
	bTeamShockBeams=True
	bSniperTraceEffects=True
	bFWS=True
	bShowLowAmmoWarning=True
	BeepSoundType=0
	SniperScopeStyle=1
	ChatAreaPosition=0
	bShowTeamMatesLocation=True
	bShowFlagsLocation=True
}