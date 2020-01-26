class IndiaSettingsMenuPage extends UMenuPageWindow;

var UWindowCheckbox bFastWeapon, bDI, bTSB, bSniperTrace, bLowAmWarn, bTeamLocation, bFlagLocation;
var UWindowComboControl NNSniperStyle, ChatPos, BeepSound, HUDSy;

var UWindowSmallButton Close;

function Created()
{
	Super.Created();

	bFastWeapon = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 20, WinWidth - 30, 1));
	bFastWeapon.bAcceptsFocus=False;
	bFastWeapon.SetText("Fast Weapon Switching");
	bFastWeapon.SetFont(F_Normal);
	bFastWeapon.Align=TA_Left;
	bFastWeapon.bChecked=Class'IndiaSettings'.default.bFWS;

	bDI = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 40, WinWidth - 30, 1));
	bDI.bAcceptsFocus=False;
	bDI.SetText("Show Damage Indicator");
	bDI.SetFont(F_Normal);
	bDI.Align=TA_Left;
	bDI.bChecked=Class'IndiaSettings'.default.bDamageIndicator;

	bTSB = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 60, WinWidth - 30, 1));
	bTSB.bAcceptsFocus=False;
	bTSB.SetText("Team-Based Shock Effects");
	bTSB.SetFont(F_Normal);
	bTSB.Align=TA_Left;
	bTSB.bChecked=Class'IndiaSettings'.default.bTeamShockBeams;
	
	bSniperTrace = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 80, WinWidth - 30, 1));
	bSniperTrace.bAcceptsFocus=False;
	bSniperTrace.SetText("Sniper Trace Effects");
	bSniperTrace.SetFont(F_Normal);
	bSniperTrace.Align=TA_Left;
	bSniperTrace.bChecked=Class'IndiaSettings'.default.bSniperTraceEffects;
	
	bLowAmWarn = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 100, WinWidth - 30, 1));
	bLowAmWarn.bAcceptsFocus=False;
	bLowAmWarn.SetText("Show Low Ammo Warning");
	bLowAmWarn.SetFont(F_Normal);
	bLowAmWarn.Align=TA_Left;
	bLowAmWarn.bChecked=Class'IndiaSettings'.default.bShowLowAmmoWarning;

	BeepSound = UWindowComboControl(CreateControl(class'UWindowComboControl', 10, 120, WinWidth - 30, 1));
   	BeepSound.SetFont(F_Normal);
   	BeepSound.EditBoxWidth = 80;
   	BeepSound.AddItem("Default", "0");
   	BeepSound.AddItem("Q3", "1");
   	BeepSound.SetSelectedIndex(class'IndiaSettings'.default.BeepSoundType);
   	BeepSound.SetEditable(False);
   	BeepSound.Text = "Beep Sound Type ";

	NNSniperStyle = UWindowComboControl(CreateControl(class'UWindowComboControl', 10, 140, WinWidth - 30, 1));
   	NNSniperStyle.SetFont(F_Normal);
   	NNSniperStyle.EditBoxWidth = 80;
   	NNSniperStyle.AddItem("Default", "0");
   	NNSniperStyle.AddItem("Tactical", "1");
   	NNSniperStyle.AddItem("Sci-Fi", "2");
   	NNSniperStyle.AddItem("None", "3");
   	NNSniperStyle.SetSelectedIndex(class'IndiaSettings'.default.SniperScopeStyle);
   	NNSniperStyle.SetEditable(False);
   	NNSniperStyle.Text = "Sniper Scope Style";
	
	ChatPos = UWindowComboControl(CreateControl(class'UWindowComboControl', 10, 160, WinWidth - 30, 1));
   	ChatPos.SetFont(F_Normal);
   	ChatPos.EditBoxWidth = 100;
   	ChatPos.AddItem("Top-Corner", "0");
   	ChatPos.AddItem("Bottom-Corner", "1");
   	ChatPos.SetSelectedIndex(class'IndiaSettings'.default.ChatAreaPosition);
   	ChatPos.SetEditable(False);
   	ChatPos.Text = "Chat and Messages Area Position";

   	bTeamLocation = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 180, WinWidth - 30, 1));
	bTeamLocation.bAcceptsFocus=False;
	bTeamLocation.SetText("Show Team Mates location");
	bTeamLocation.SetFont(F_Normal);
	bTeamLocation.Align=TA_Left;
	bTeamLocation.bChecked=Class'IndiaSettings'.default.bShowTeamMatesLocation;

	bFlagLocation = UWindowCheckbox(CreateControl(Class'UWindowCheckbox',10, 200, WinWidth - 30, 1));
	bFlagLocation.bAcceptsFocus=False;
	bFlagLocation.SetText("Show CTF Flags location");
	bFlagLocation.SetFont(F_Normal);
	bFlagLocation.Align=TA_Left;
	bFlagLocation.bChecked=Class'IndiaSettings'.default.bShowFlagsLocation;

   	Close = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth - 100,WinHeight - 30,80.0,35.0));
    Close.SetText("Close");
    Close.DownSound = Sound'WindowClose';
    Close.NotifyWindow = Self;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C,E);

	switch(E) {
		case DE_Change: 
			switch(C) {
				case bFastWeapon:
					if(bFastWeapon != None)
					{
						class'IndiaSettings'.default.bFWS = bFastWeapon.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case bDI:
					if(bDI != None)
					{
						class'IndiaSettings'.default.bDamageIndicator = bDI.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case bTSB:
					if(bTSB != None)
					{
						class'IndiaSettings'.default.bTeamShockBeams = bTSB.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case BeepSound:
					if(BeepSound != None)
					{
						class'IndiaSettings'.default.BeepSoundType = byte(BeepSound.GetValue2());
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case bSniperTrace:
					if(bSniperTrace != None)
					{
						class'IndiaSettings'.default.bSniperTraceEffects = bSniperTrace.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case bLowAmWarn:
					if(bLowAmWarn != None)
					{
						class'IndiaSettings'.default.bShowLowAmmoWarning = bLowAmWarn.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case NNSniperStyle:
					if(NNSniperStyle != None)
					{
               			class'IndiaSettings'.default.SniperScopeStyle = byte(NNSniperStyle.GetValue2());
               			class'IndiaSettings'.static.StaticSaveConfig();
               		}
               		break;
				case ChatPos:
					if(ChatPos != None)
					{
               			class'IndiaSettings'.default.ChatAreaPosition = byte(ChatPos.GetValue2());
               			class'IndiaSettings'.static.StaticSaveConfig();
               		}
               		break;
               	case bTeamLocation:
					if(bTeamLocation != None)
					{
						class'IndiaSettings'.default.bShowTeamMatesLocation = bTeamLocation.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
				case bFlagLocation:
					if(bFlagLocation != None)
					{
						class'IndiaSettings'.default.bShowFlagsLocation = bFlagLocation.bChecked;
						class'IndiaSettings'.static.StaticSaveConfig();
					}
					break;
               	}
               	break;

               	case DE_Click:
				switch(C)
		        {
				 	case Close:
				 		if(Close != None)
				 		{
				 			Class'IndiaSettings'.static.StaticSaveConfig();
							SaveConfig();
		               		ParentWindow.ParentWindow.Close();
		               	}
		               	break;
		        }
		    break;
        }
}

defaultproperties
{
}