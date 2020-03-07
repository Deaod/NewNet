//=============================================================================
// TBoss.
//=============================================================================
class bbTBoss extends bbTournamentMale;


static function SetMultiSkin(Actor SkinActor, string SkinName, string FaceName, byte TeamNum)
{
	local string MeshName, SkinItem, SkinPackage;

	MeshName = SkinActor.GetItemName(string(SkinActor.Mesh));

	SkinItem = SkinActor.GetItemName(SkinName);
	SkinPackage = Left(SkinName, Len(SkinName) - Len(SkinItem));

	if(SkinPackage == "")
	{
		SkinPackage="BossSkins.";
		SkinName=SkinPackage$SkinName;
	}

	if( TeamNum != 255 )
	{
		if(!SetSkinElement(SkinActor, 0, SkinName$"1T_"$String(TeamNum), default.DefaultSkinName$"1T_"$String(TeamNum)))
		{
			if(!SetSkinElement(SkinActor, 0, SkinName$"1", default.DefaultSkinName$"1"))
			{
				SetSkinElement(SkinActor, 0, default.DefaultSkinName$"1T_"$String(TeamNum), default.DefaultSkinName$"1T_"$String(TeamNum));
				SkinName=default.DefaultSkinName;
			}
		}
		SetSkinElement(SkinActor, 1, SkinName$"2T_"$String(TeamNum), SkinName$"2T_"$String(TeamNum));
		SetSkinElement(SkinActor, 2, SkinName$"3T_"$String(TeamNum), SkinName$"3T_"$String(TeamNum));
		SetSkinElement(SkinActor, 3, SkinName$"4T_"$String(TeamNum), SkinName$"4T_"$String(TeamNum));
	}
	else
	{
		if(!SetSkinElement(SkinActor, 0, SkinName$"1", default.DefaultSkinName))
			SkinName=default.DefaultSkinName;

		SetSkinElement(SkinActor, 1, SkinName$"2", SkinName$"2");
		SetSkinElement(SkinActor, 2, SkinName$"3", SkinName$"3");
		SetSkinElement(SkinActor, 3, SkinName$"4", SkinName$"4");
	}

	if( Pawn(SkinActor) != None ) 
		Pawn(SkinActor).PlayerReplicationInfo.TalkTexture = Texture(DynamicLoadObject(SkinName$"5Xan", class'Texture'));
}

defaultproperties
{
     FakeClass="Botpack.TBoss"
     Deaths(0)=Sound'Botpack.Boss.BDeath1'
     Deaths(1)=Sound'Botpack.Boss.BDeath1'
     Deaths(2)=Sound'Botpack.Boss.BDeath3'
     Deaths(3)=Sound'Botpack.Boss.BDeath4'
     Deaths(4)=Sound'Botpack.Boss.BDeath3'
     Deaths(5)=Sound'Botpack.Boss.BDeath4'
     FaceSkin=1
     DefaultSkinName="BossSkins.Boss"
     HitSound3=Sound'Botpack.Boss.BInjur3'
     HitSound4=Sound'Botpack.Boss.BInjur4'
     LandGrunt=Sound'Botpack.Boss.Bland01'
     StatusDoll=Texture'Botpack.Icons.BossDoll'
     StatusBelt=Texture'Botpack.Icons.BossBelt'
     VoicePackMetaClass="BotPack.VoiceBoss"
     CarcassType=Class'Botpack.TBossCarcass'
     JumpSound=Sound'Botpack.Boss.BJump1'
     SelectionMesh="Botpack.SelectionBoss"
     SpecialMesh="Botpack.TrophyBoss"
     HitSound1=Sound'Botpack.Boss.BInjur1'
     HitSound2=Sound'Botpack.Boss.BInjur2'
     Die=Sound'Botpack.Boss.BDeath1'
     MenuName="Boss"
     VoiceType="BotPack.VoiceBoss"
     Mesh=LodMesh'Botpack.Boss'
}
