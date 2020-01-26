class NNTeamShock expands Object;

var Texture mSkin[5];
var Texture mSkin3[5];
var Texture mSkin4[5];

static function SetTeamSkins( ShockRifle S)
{
	local int Team;

	Team = static.FVOwnerTeam( S);
	S.MultiSkins[1] = default.mSkin[ Team ];
	S.MultiSkins[7] = S.MultiSkins[1];
	S.MultiSkins[2] = default.mSkin3[ Team ];
	S.MultiSkins[3] = default.mSkin4[ Team ];
}

static final function int FVOwnerTeam( Actor Other)
{
	return FVTeam( Pawn(Other.Owner) );
}

static final function int FVTeam( Pawn Other)
{
	if ( Other == none || Other.PlayerReplicationInfo == none )
		return 4;
	return Min( Other.PlayerReplicationInfo.Team, 4);
}

defaultproperties
{
	mSkin(0)=Texture'ASMD_t_0'
	mSkin(1)=Texture'Botpack.ASMD_t'
	mSkin(2)=Texture'ASMD_t_2'
	mSkin(3)=Texture'ASMD_t_3'
	mSkin(4)=Texture'Botpack.ASMD_t'
	mSkin3(0)=Texture'ASMD_t3_0'
	mSkin3(1)=Texture'Botpack.ASMD_t3'
	mSkin3(2)=Texture'ASMD_t3_2'
	mSkin3(3)=Texture'ASMD_t3_3'
	mSkin3(4)=Texture'Botpack.ASMD_t3'
	mSkin4(0)=Texture'ASMD_t4_0'
	mSkin4(1)=Texture'Botpack.ASMD_t4'
	mSkin4(2)=Texture'ASMD_t4_2'
	mSkin4(3)=Texture'ASMD_t4_3'
	mSkin4(4)=Texture'Botpack.ASMD_t4'
}
