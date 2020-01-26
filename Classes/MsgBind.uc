class MsgBind extends LocalMessagePlus;

#exec OBJ LOAD FILE=..\System\UnrealShare.u PACKAGE=UnrealShare


var string MsgStr;

static function string GetString(
optional int Switch,
optional PlayerReplicationInfo RelatedPRI_1,
optional PlayerReplicationInfo RelatedPRI_2,
optional Object OptionalObject
)
{
	return Default.MsgStr;
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

	P.ClientPlaySound( sound'UnrealShare.Generic.Beep' );
}

defaultproperties
{
     MsgStr="To bind offhand grapple, type in console:  MUTATE OFFHAND <KEY>"
     Lifetime=10
     DrawColor=(G=41,B=148)
}
