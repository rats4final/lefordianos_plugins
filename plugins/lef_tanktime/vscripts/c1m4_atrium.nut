// Valve's script from today's game (left4dead2/pak01), plus Tank!Time!'s changes for mutation19 only.
// Script de Valve del juego actual (left4dead2/pak01), mas los cambios de Tank!Time! solo para mutation19.
// Built for lef_tanktime (lefordianos_plugins); based on Merc1less' Tank!Time! 1.2.3.
Msg(" atrium map script "+"\n")

// number of cans needed to escape.

if ( Director.IsSinglePlayerGame() )
{
	NumCansNeeded <- 8
}
else if ( Director.GetGameMode() == "mutation19" )
{
	NumCansNeeded <- 6
}
else
{
	NumCansNeeded <- 13
}


DirectorOptions <-
{
	
CommonLimit = 15

}

NavMesh.UnblockRescueVehicleNav()

EntFire( "progress_display", "SetTotalItems", NumCansNeeded )


function GasCanPoured(){}