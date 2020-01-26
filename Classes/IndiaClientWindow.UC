class IndiaClientWindow extends UWindowDialogClientWindow;

var UWindowSmallCloseButton CloseButton;
var UWindowPageControl GameSettings;

function Created()
{
	local class<UWindowPageWindow> PageClass;

	WinLeft = int(Root.WinWidth - WinWidth) / 2;
    WinTop = int(Root.WinHeight - WinHeight) / 2;

	Super.Created();

	SetSize(300,400);
	WinWidth = 300;
	WinHeight = 400;

	GameSettings = UWindowPageControl(CreateWindow(class'UWindowPageControl', 0, 0, WinWidth, WinHeight));
	GameSettings.SetMultiLine(False);
	GameSettings.AddPage("UL v0.6 Settings", class'IndiaSettingsMenuPage');
}

defaultproperties
{
}