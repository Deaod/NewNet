class Ul06DB extends Actor;

#exec TEXTURE IMPORT FILE=TEXTURES\Bluer.PCX MIPS=OFF GROUP=TeamShock NAME=Bluer
#exec TEXTURE IMPORT FILE=TEXTURES\BlueSW.PCX MIPS=OFF GROUP=TeamShock2 NAME=BlueSW
#exec TEXTURE IMPORT FILE=TEXTURES\BlueS.PCX MIPS=OFF GROUP=TeamShock3 NAME=BlueS
#exec TEXTURE IMPORT FILE=TEXTURES\Goldr.PCX MIPS=OFF GROUP=TeamShock NAME=Goldr
#exec TEXTURE IMPORT FILE=TEXTURES\GoldSW.PCX MIPS=OFF GROUP=TeamShock2 NAME=GoldSW
#exec TEXTURE IMPORT FILE=TEXTURES\GoldS.PCX MIPS=OFF GROUP=TeamShock3 NAME=GoldS
#exec TEXTURE IMPORT FILE=TEXTURES\Greenr.PCX MIPS=OFF GROUP=TeamShock NAME=Greenr
#exec TEXTURE IMPORT FILE=TEXTURES\GreenSW.PCX MIPS=OFF GROUP=TeamShock2 NAME=GreenSW
#exec TEXTURE IMPORT FILE=TEXTURES\GreenS.PCX MIPS=OFF GROUP=TeamShock3 NAME=GreenS
#exec TEXTURE IMPORT NAME=FlgTaken FILE=TEXTURES\FlgTaken.PCX GROUP="HUD" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=FlgHome FILE=TEXTURES\FlgHome.PCX GROUP="HUD" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT FILE=TEXTURES\Lt.PCX MIPS=OFF GROUP=DamageIndicator NAME=Lt
#exec TEXTURE IMPORT FILE=TEXTURES\Rt.PCX MIPS=OFF GROUP=DamageIndicator NAME=Rt
#exec TEXTURE IMPORT FILE=TEXTURES\Fw.PCX MIPS=OFF GROUP=DamageIndicator NAME=Fw
#exec TEXTURE IMPORT FILE=TEXTURES\Bw.PCX MIPS=OFF GROUP=DamageIndicator NAME=Bw
#exec TEXTURE IMPORT FILE=TEXTURES\Scope1.PCX MIPS=OFF GROUP=SniperScope NAME=Scope1
#exec TEXTURE IMPORT FILE=TEXTURES\Scope2.PCX MIPS=OFF GROUP=SniperScope NAME=Scope2
#exec Texture Import NAME=TeamBeacon2 File="Textures\TeamBeacon2.PCX" Group=Hud Flags=2
#exec New TrueTypeFontFactory FontName="LucidaSansTypewriter" Name="BeaconNameFontSmall"  Height=8  USize=256 VSize=128 CharactersPerPage=256
#exec New TrueTypeFontFactory FontName="LucidaSansTypewriter" Name="BeaconNameFontMedium" Height=10 USize=256 VSize=128 CharactersPerPage=256
#exec New TrueTypeFontFactory FontName="LucidaSansTypewriter" Name="BeaconNameFontLarge"  Height=12 USize=256 VSize=256 CharactersPerPage=256
#exec TEXTURE IMPORT FILE=TEXTURES\Redr.PCX MIPS=OFF GROUP=TeamShock NAME=Redr
#exec TEXTURE IMPORT FILE=TEXTURES\RedSW.PCX MIPS=OFF GROUP=TeamShock2 NAME=RedSW
#exec TEXTURE IMPORT FILE=TEXTURES\RedS.PCX MIPS=OFF GROUP=TeamShock3 NAME=RedS

#exec MESH IMPORT MESH=railtrail ANIVFILE=MODELS\railtrail_a.3d DATAFILE=MODELS\railtrail_d.3d X=0 Y=0 Z=0
#exec MESH ORIGIN MESH=railtrail X=0 Y=0 Z=0 PITCH=0
#exec MESH SEQUENCE MESH=railtrail SEQ=All      STARTFRAME=0 NUMFRAMES=2
#exec MESH SEQUENCE MESH=railtrail SEQ=railtrail STARTFRAME=0 NUMFRAMES=1
#exec MESH SEQUENCE MESH=railtrail SEQ=getbig STARTFRAME=0 NUMFRAMES=2 RATE=1
#exec MESHMAP NEW   MESHMAP=railtrail MESH=railtrail
#exec MESHMAP SCALE MESHMAP=railtrail X=0.75 Y=0.05 Z=0.2

#exec OBJ LOAD FILE=AnimTex\TeamShocking.utx PACKAGE=UltimateNewnetv0_6_Database.TeamShock4

#exec Texture Import File=Textures\NewNetLogo.BMP Name=NewNetLogo Mips=Off
#exec Texture Import File=Textures\bootbit.BMP Name=PureBoots Mips=Off
#exec Texture Import File=Textures\hudbgplain.BMP Name=PureTimeBG Mips=Off
#exec Texture Import File=Textures\smallwhitething.BMP Name=PureSWT Mips=Off

defaultproperties
{
}