// Valve's script from today's game (left4dead2_dlc1/pak01), plus Tank!Time!'s changes for mutation19 only.
// Script de Valve del juego actual (left4dead2_dlc1/pak01), mas los cambios de Tank!Time! solo para mutation19.
// Built for lef_tanktime (lefordianos_plugins); based on Merc1less' Tank!Time! 1.2.3.
Msg("Quieting director\n");

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
	NumCansNeeded <- 16
	Msg("---------------------------MULTI PLAYER\n");
}
if ( !Director.IsSinglePlayerGame() && Director.GetGameMode() == "mutation19" )
{
	NumCansNeeded <- 6
}

EntFire( "progress_display", "SetTotalItems", NumCansNeeded )


function GasCanPoured(){}