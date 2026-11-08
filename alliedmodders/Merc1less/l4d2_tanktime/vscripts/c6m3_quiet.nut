//-----------------------------------------------------
// The Original script was written by valve
//-----------------------------------------------------
Msg("Quieting director a little bit - but not in mutation19!\n");

DirectorOptions <-
{
ProhibitBosses = true
SpecialRespawnInterval = 999999
CommonLimit = 0
}

// number of cans needed to escape.
if ( Director.IsSinglePlayerGame() )
{
	NumCansNeeded <- 10

	Msg("---------------------------SINGLE PLAYER\n");
}
else
{
	if ( Director.GetGameMode() == "mutation19")
	{
		NumCansNeeded <- 6
		Msg("---------------------------MUTATION19\n");
	}
	else
	{
		NumCansNeeded <- 16
		Msg("---------------------------MULTI PLAYER\n");
	}
}

EntFire( "progress_display", "SetTotalItems",NumCansNeeded)

function GasCanPoured(){}

