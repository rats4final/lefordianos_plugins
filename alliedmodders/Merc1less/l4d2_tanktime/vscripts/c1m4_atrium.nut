//-----------------------------------------------------
// The Original script was written by valve
//-----------------------------------------------------
Msg(" atrium map script "+"\n")

// number of cans needed to escape.

if ( Director.IsSinglePlayerGame() )
{
	NumCansNeeded <- 8
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
		NumCansNeeded <- 13
	}
}


DirectorOptions <-
{

CommonLimit = 15

}

NavMesh.UnblockRescueVehicleNav()

EntFire( "progress_display", "SetTotalItems", NumCansNeeded )


function GasCanPoured(){} 