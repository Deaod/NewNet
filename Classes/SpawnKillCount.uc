class SpawnKillCount expands SpawnNotify config;

//Let's add to the pawns the kill count feature which is required to count the kills and eff.
simulated event Actor SpawnNotification(actor A){
	local KillCountLMSPRI MPRI;
	
	if ( A.IsA('Pawn') && !A.IsA('Spectator') ){
		MPRI = Spawn(Class'KillCountLMSPRI', Pawn(A).PlayerReplicationInfo,, A.Location);
	}
	return A;
}
