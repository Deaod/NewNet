class ST_UTApeChunkInfo extends Info;

var Actor Victim[16];
var int HitCount;
var int ChunkCount;
var int zzNN_ProjIndex;

function AddChunk(ST_UTApeChunk Chunk)
{
	if (Chunk == None)
		return;				// If it for some reason failed to spawn.
	Chunk.Chunkie = Self;
	Chunk.ChunkIndex = ChunkCount++;
}

function HitSomething(ST_UTApeChunk Chunk, Actor Other)
{
	local Actor A;
	local int x;

	HitCount++;
	Victim[Chunk.ChunkIndex] = Other;

	if (HitCount == ChunkCount)
	{
		Destroy();			// Not really destroyed immediately, so we can do it this way :P
		if (ChunkCount != 16)
			return;			// Flak Slugs produce only 5 chunks.

		A = Victim[0];
		if (!A.IsA('Pawn'))
			return;			// Only give perfects for pawns (Not carcasses etc)

		for (x = 1; x < ChunkCount; x++)
			if (Victim[x] != A)
				return;
	}
}

defaultproperties
{
     LifeSpan=2.000000
}
