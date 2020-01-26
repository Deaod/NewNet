class NNSetShock expands Object;

var Texture mSkin;
var Texture mSkin3;
var Texture mSkin4;

static function SetTeamSkins( ST_SiegeInstaGibRifle S)
{
	S.MultiSkins[1] = default.mSkin;
	S.MultiSkins[7] = S.MultiSkins[1];
	S.MultiSkins[2] = default.mSkin3;
	S.MultiSkins[3] = default.mSkin4;
}

defaultproperties
{
	mSkin=Texture'ASMD_t_2'
	mSkin3=Texture'ASMD_t3_2'
	mSkin4=Texture'ASMD_t4_2'
}
