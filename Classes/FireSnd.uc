class FireSnd extends Actor;

// Owner.PlaySound() doesn't work, but should.
// This dirty workaround does the same..

var float TRdiv, cnt;

function Tick(float DeltaTime)
{
if(cnt==0)
{
AmbientSound=sound'Fire';
TRdiv = 1/int(ConsoleCommand("get IpDrv.TcpNetDriver NetServerMaxTickRate"));
}
cnt+=TRdiv;
if(cnt>=0.4) // Plays about 0.4s
{
AmbientSound=none;
Destroy();
}
}

defaultproperties
{
     bHidden=True
     SoundRadius=80
     SoundVolume=255
}
