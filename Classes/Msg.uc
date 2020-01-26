class Msg expands LocalMessagePlus;

var localized string MsgStr;

static function float GetOffset(int Switch, float YL, float ClipY )
{
        return ClipY - YL * 2 - 0.0833*ClipY;
}

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
return Default.MsgStr;
}

defaultproperties
{
     MsgStr="Jump to release hook"
     FontSize=1
     bIsSpecial=True
     bIsUnique=True
     bIsConsoleMessage=False
     Lifetime=1
     DrawColor=(R=122,G=202)
     YPos=196.000000
     bCenter=True
}
