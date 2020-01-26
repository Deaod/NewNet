class FlagMsg extends Msg;

var localized string MsgStr;

static function float GetOffset(int Switch, float YL, float ClipY )
{
        return ClipY - YL * 0.5 - 0.0833*ClipY;
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
}
