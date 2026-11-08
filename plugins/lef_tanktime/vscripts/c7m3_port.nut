// Valve's script from today's game (left4dead2_dlc2/pak01), plus Tank!Time!'s changes for mutation19 only.
// Script de Valve del juego actual (left4dead2_dlc2/pak01), mas los cambios de Tank!Time! solo para mutation19.
// Built for lef_tanktime (lefordianos_plugins); based on Merc1less' Tank!Time! 1.2.3.
//-----------------------------------------------------
//
//
//-----------------------------------------------------
Msg("Initiating c7m3_port script\n");

DirectorOptions <-
{
	TankLimit = 0
	WitchLimit = 0
	ProhibitBosses = true
}

if ( Director.GetGameMode() == "mutation19" )
{
	DirectorOptions.ProhibitBosses = false
}



function GeneratorButtonPressed()
{
    Msg("**c7m3_port GeneratorButtonPressed **\n")    
	EntFire( "@director", "EndScript" )
	EntFire( "generator_start_model", "Enable" )
    EntFire( "generator_start_model", "ForceFinaleStart" )
	EntFire( "generator_start_model", "Disable" )
}
