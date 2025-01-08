/*
**  midair.as by THRESHER
**      Idle & Support #warsow.na @ Quakenet
**  date: 9/26/09
**
**  notes: if you use this midair.as file, please keep my credits in/give me credit :D
**          And let me know what you/*
**  midair.as by THRESHER
**      Idle & Support #warsow.na @ Quakenet
**  date: 9/26/09
**
**  notes: if you use this midair.as file, please keep my credits in/give me credit :D
**          And let me know what you use it in, that would be awesome.
**
**         Sorry for the dirty release :P
**
**
** team midair by Jerm
** fix for 1.0 by Brafilus
** team midair fix by Schaff & Brafilus (sry for the nasty stuff :P)
*/

const int P_WALK_SPEED = 320;
const int P_AIR_SPEED  = 0;
const int GOLD_MIDAIR  = 500;
const int DIAMOND_MIDAIR = 1000;
const int BONGO_MIDAIR = 1500;

// ammount of kills needed for awards
const int KA1 = 3;  // minimum for check of awards
const int KA2 = 5;
const int KA3 = 10;
const int KA4 = 15;
const int KA5 = 20;

int prcYesIcon = 0;
int prcShockIcon = 0;
int prcShellIcon = 0;

int pAirControl = 0;    // air control var  ( air control is off by default )
//uint pMidHeight  = 152;    // height var  ( 152 is default )

//int pHealth = 100;
//int pArmor  = 100;

Cvar g_mid_aircontrol( "g_mid_aircontrol", "0", CVAR_ARCHIVE );
Cvar g_mid_noquad( "g_mid_noquad", "1", CVAR_ARCHIVE );
Cvar g_mid_weakonly( "g_mid_weakonly", "0", CVAR_ARCHIVE );
Cvar g_mid_height( "g_mid_height", "172", CVAR_ARCHIVE );       // minimum value 25, default 172( used to be 152 )
Cvar g_mid_hpap( "g_mid_hpap", "0", CVAR_ARCHIVE );
Cvar g_mid_walljump( "g_mid_walljump", "0", CVAR_ARCHIVE );
Cvar g_mid_enableGL( "g_mid_enableGL", "0", CVAR_ARCHIVE );   // done
Cvar g_mid_spawnrape( "g_mid_spawnrape", "1", CVAR_ARCHIVE ); // in progress

Cvar g_mid_knockback( "g_mid_knockback", "1", CVAR_ARCHIVE ); // turns g_mid_kbscale on/off
Cvar g_mid_kbscale( "g_mid_kbscale", "2.8", CVAR_ARCHIVE ); // knockback scale value
Cvar g_mid_team( "g_mid_team", "1", CVAR_ARCHIVE );   //1 turns Challengers_queue on with maxteamplayers 1
                                                      //<number over 1> turns Challengers_queue off with maxteamplayers <number>
Cvar g_challengers_queue( "g_challengers_queue", "1", CVAR_SERVERINFO|CVAR_ARCHIVE );   //Toggles Challengers queue on/off
Cvar g_teams_maxplayers( "g_teams_maxplayers", "1", CVAR_SERVERINFO|CVAR_ARCHIVE );   //changes teams maxplayers number

Cvar mapName( "mapname", "", 0 );
Cvar knockScale( "g_knockback_scale", "1", 0 ); //default value set to 1

int siUberMidair = 0;
int siEradication = 0;
int siGoldMidair = 0;
int siDiamondMidair = 0;

///*****************************************************************
/// NEW MAP ENTITY DEFINITIONS
///*****************************************************************



///*****************************************************************
/// LOCAL FUNCTIONS --------- /midair/functions.as
///*****************************************************************


void setUpClients(bool all)
{
/*	if(all)
		G_Print("setup clients all\n");
	else
		G_Print("setup clients queue/spec only\n");
*/	
	
    if( g_mid_team.integer == 0 || g_mid_team.integer == 1)
        return;
		
    for ( int i = 0; i < maxClients; i++ )
    {
		Client @clientH = @G_GetClient( i );
		if(@clientH != null) 
		{
			if ( (clientH.state() >= CS_CONNECTED) && ((clientH.team == TEAM_SPECTATOR) || (clientH.team == TEAM_PLAYERS) || all) )
			{
				clientH.execGameCommand( "cmd leavequeue;\n" );
				clientH.team = TEAM_SPECTATOR;
			}
			
		    Entity @ent = @clientH.getEnt();
			if(@ent != null)
			{
				if ( (ent.client.state() >= CS_CONNECTED) && ((ent.team == TEAM_SPECTATOR) || (ent.team == TEAM_PLAYERS) || all) )
				{
					ent.client.execGameCommand( "cmd leavequeue;\n" );
					
					ent.client.team = TEAM_SPECTATOR;
					ent.team = TEAM_SPECTATOR;
				}
					
				//if (ent.client.state() >= CS_CONNECTED)	
				//	ent.client.execGameCommand("cmd say ping;\n");
			}
		}
		
    }   
	
}

void dropOutFromQueue()
{

		
    for ( int i = 0; i < maxClients; i++ )
    {
		Client @clientH = @G_GetClient( i );
		if(@clientH != null) 
		{
			if (clientH.state() >= CS_CONNECTED)
			{
				clientH.execGameCommand( "cmd leavequeue;\n" );
				clientH.team = TEAM_SPECTATOR;
				
			}
			
		    Entity @ent = @clientH.getEnt();
			if(@ent != null)
			{
				if ( ent.client.state() >= CS_CONNECTED )
				{
					ent.client.execGameCommand( "cmd leavequeue;\n" );
					ent.client.team = TEAM_SPECTATOR;
					ent.team = TEAM_SPECTATOR;
				}
					
			}
		}
		
    }   
}

void setupTeamMidair(bool firstSet)
{

	if(firstSet == false)
	{
		// ingame set by vote
		setUpClients(false);
		//G_CmdExecute("match restart\n");
	}
	else
	{
		setUpClients(true);
	}
	
	
    //Jerm's begin
    if ( g_mid_team.integer == 1 )
    {
        gametype.hasChallengersQueue = true;
        g_challengers_queue.set( 1 );
        gametype.maxPlayersPerTeam = 1;
        g_teams_maxplayers.set( 1 );
        
    }
    else
    {
        gametype.hasChallengersQueue = false;
        g_challengers_queue.set( 0 );
        gametype.maxPlayersPerTeam = g_mid_team.integer;
        g_teams_maxplayers.set( g_mid_team.integer );
	
    }
    //Jerm's end
	
	if(firstSet == false)
	{
		// ingame set by vote
		setUpClients(false);
		//G_CmdExecute("match restart\n");
	}
	else
	{
		setUpClients(true);
	}
	
}


//return the ruleset string
String MIDAIR_DisplayRuleset()
{
  String toggle;
  String _pivot;
  String response = S_COLOR_WHITE + "----------------------------\n";
  response += S_COLOR_CYAN + "Midair Air Ruleset\n";
  response += S_COLOR_WHITE + "----------------------------\n";

  response += S_COLOR_YELLOW + "Aircontrol: " + S_COLOR_GREEN + g_mid_aircontrol.integer;
  response += S_COLOR_WHITE + "        ( callvote aircontrol 0|1|2 )\n";

      if ( g_mid_hpap.boolean )
          toggle = S_COLOR_GREEN + "ENABLED ";
      else
          toggle = S_COLOR_RED + "DISABLED";

  response += S_COLOR_YELLOW + "Health and Armor: " + toggle;
  response += S_COLOR_WHITE + "  ( callvote healtharmor 0|1 )\n";

      if ( g_mid_height.integer == 172 )
          toggle = S_COLOR_GREEN + g_mid_height.integer;
      else
          toggle = S_COLOR_MAGENTA + g_mid_height.integer;

  response += S_COLOR_YELLOW + "Frag Height: " + toggle; 
  response += S_COLOR_WHITE + "       ( NOT VOTABLE )\n";

      if ( !g_mid_walljump.boolean )
          toggle = S_COLOR_RED + "DISABLED";
      else
          toggle = S_COLOR_GREEN + "ENABLED ";

  response += S_COLOR_YELLOW + "Wall Jump: " + toggle;
  response += S_COLOR_WHITE + "         ( callvote walljump 0|1 )\n";

      if ( !g_mid_weakonly.boolean )
          toggle = S_COLOR_RED + "DISABLED";
      else
          toggle = S_COLOR_GREEN + "ENABLED ";

  response += S_COLOR_YELLOW + "Weak Ammo Only: " + toggle;
  response += S_COLOR_WHITE + "    ( callvote weakonly 0|1 )\n";

      if ( !g_mid_enableGL.boolean )
          toggle = S_COLOR_RED + "DISABLED";
      else
          toggle = S_COLOR_GREEN + "ENABLED ";

  response += S_COLOR_YELLOW + "Grenade Launcher: " + toggle;
  response += S_COLOR_WHITE + "  ( callvote enablegl 0|1 )\n";

      if ( !g_mid_noquad.boolean )
          toggle = S_COLOR_GREEN + "ON";
      else
          toggle = S_COLOR_RED + "OFF";

  response += S_COLOR_YELLOW + "Quad Powerup: " + toggle;
  response += S_COLOR_WHITE + "      ( callvote noquad 0|1 )\n";

      if ( g_mid_spawnrape.boolean )
          toggle = S_COLOR_GREEN + "ENABLED ";
      else
          toggle = S_COLOR_RED + "DISABLED";

  response += S_COLOR_YELLOW + "Spawn Raping: " + toggle;
  response += S_COLOR_WHITE + "      ( callvote spawnrape 0|1 )\n";

      if ( g_mid_knockback.boolean )
          toggle = S_COLOR_GREEN + "ENABLED ";
      else
          toggle = S_COLOR_RED + "DISABLED";

  response += S_COLOR_YELLOW + "Knockback Scaling: " + toggle;
  response += S_COLOR_WHITE + " ( callvote knockback 0|1 )\n";

      if ( g_mid_kbscale.integer == 2.8 )
          toggle = S_COLOR_GREEN + g_mid_kbscale.value;
      else
          toggle = S_COLOR_RED + g_mid_kbscale.value;

  response += S_COLOR_YELLOW + "Knockback Scale: " + toggle ;
  response += S_COLOR_WHITE + "  ( NOT VOTABLE )\n";

      if ( g_mid_team.integer == 1 )
          toggle = S_COLOR_GREEN + g_mid_team.integer;
      else
          toggle = S_COLOR_RED + g_mid_team.integer;

  response += S_COLOR_YELLOW + "Team midair: " + toggle ;
  response += S_COLOR_WHITE + "  ( callvote team_midair number )\n";
  
  response += S_COLOR_WHITE + "----------------------------\n";
  
  return response;
}

//function that calculates the score
int MIDAIR_SCORE_NET( Stats @stats )
{
    if ( @stats == null )
        return 0;

    return ( stats.frags - ( stats.teamFrags + stats.suicides ) );
}

// a player has just died. The script is warned about it so it can account scores
void MIDAIR_playerKilled( Entity @target, Entity @attacker, Entity @inflicter )
{

    if ( match.getState() != MATCH_STATE_PLAYTIME )
        return;

    // update player score based on player stats
    if ( @target.client == null )
        return;

    //set score for the attacker
    if ( @attacker != null && @attacker.client != null )
        attacker.client.stats.setScore( MIDAIR_SCORE_NET( attacker.client.stats ) );

    //set score for the target
    target.client.stats.setScore( MIDAIR_SCORE_NET( target.client.stats ) );

    Team @team;
  
    //set score for the target's team
    @team = @G_GetTeam( target.team );
    team.stats.setScore( team.stats.frags - ( team.stats.teamFrags + team.stats.suicides ) );

    //set score for the attacker's team
    @team = @G_GetTeam( target.team == TEAM_ALPHA ? TEAM_BETA : TEAM_ALPHA );
    team.stats.setScore( team.stats.frags - ( team.stats.teamFrags + team.stats.suicides ) );

    // checks for gold and diamond midair
    MidairSpecials( attacker, inflicter );

    // checks for awards
    MidairAwards( attacker, target );



    // drop items - we wont want to drop items for midair
    if ( ( G_PointContents( target.origin ) & CONTENTS_NODROP ) == 0 )
    {
        // drop the weapon with its weak ammo
        if ( target.client.weapon > WEAP_GUNBLADE )
        {
            GENERIC_DropCurrentWeapon( target.client, false );
        }
    }
}

void MIDAIR_SetUpMatch()
{
    int i, j;
    Entity @ent;
    Team @team;

    G_RemoveAllProjectiles();
    gametype.shootingDisabled = false;
    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = true;
    gametype.countdownEnabled = true;

    // clear player stats and scores, team scores and respawn clients in team lists

    for ( i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++ )
    {
        @team = @G_GetTeam( i );
        team.stats.clear();

        // respawn all clients inside the playing teams
        for ( j = 0; @team.ent( j ) != null; j++ )
        {
            @ent = @team.ent( j );
            ent.client.stats.clear(); // clear player scores & stats
            ent.client.respawn( false );
        }
    }

    // set items to be spawned with a delay
    G_Items_RespawnByType( IT_ARMOR, 0, 15 );
    G_Items_RespawnByType( IT_HEALTH, HEALTH_MEGA, 15 );
    G_Items_RespawnByType( IT_HEALTH, HEALTH_ULTRA, 15 );
    G_Items_RespawnByType( IT_POWERUP, 0, brandom( 20, 40 ) );
    G_RemoveDeadBodies();

    // resets the .kill counter
    ResetPlayerKillStats();

    // Countdowns should be made entirely client side, because we now can
    int soundindex = G_SoundIndex( "sounds/announcer/midair/midair0" + int( brandom( 1, 2 ) ) );
    G_AnnouncerSound( null, soundindex, GS_MAX_TEAMS, false, null );
        siUberMidair = G_SoundIndex("sounds/midair/midair_special");
            //G_Sound( null, CHAN_AUTO, siUberMidair, 0.1 );
    G_CenterPrintMsg( null, "MIDAIR!\n" );

    siEradication = G_SoundIndex("sounds/announcer/midair/diamond02");
}

///*****************************************************************
/// MODULE SCRIPT CALLS
///*****************************************************************

bool GT_Command( Client @client, const String &in cmdString, const String &in argsString, int argc )
{
    if ( cmdString == "drop" )
    {
        String token;

        for ( int i = 0; i < argc; i++ )
        {
            token = argsString.getToken( i );
            if ( token.len() == 0 )
                break;

            if ( token == "fullweapon" )
            {
                GENERIC_DropCurrentWeapon( client, true );
                GENERIC_DropCurrentAmmoStrong( client );
            }
            else if ( token == "weapon" )
            {
                GENERIC_DropCurrentWeapon( client, true );
            }
            else if ( token == "strong" )
            {
                GENERIC_DropCurrentAmmoStrong( client );
            }
            else
            {
                GENERIC_CommandDropItem( client, token );
            }
        }

        return true;
    }
    // example of registered command
    else if ( cmdString == "gametype" )
    {
        String response = "Midair";
        Cvar fs_game( "fs_game", "", 0 );
        String manifest = gametype.manifest;

        response += "\n";
        response += "Gametype " + gametype.name + " : " + gametype.title + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.version + "\n";
        response += "Author: " + gametype.author + "\n";
        response += "Mod: " + fs_game.string + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n";
        response += "----------------\n";

        G_PrintMsg( client.getEnt(), response );
        return true;
    }
    else if ( cmdString == "mapnum" )
    {
        String map = ML_GetMapByNum( 0 );
        G_PrintMsg( client.getEnt(), "map number: " + map );
        return true;
    }
    else if ( cmdString == "callvotevalidate" )
    {
        String votename = argsString.getToken( 0 );
        if ( votename == "aircontrol" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" && voteArg != "2" )
            {
                client.printMessage( "Callvote " + votename + " expects a 0, 1, or 2 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && g_mid_aircontrol.integer == 0 )
            {
                client.printMessage( S_COLOR_RED + "Air control is already disabled is already set to mode 0\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_aircontrol.integer == 1 )
            {
                client.printMessage( S_COLOR_RED + "Air control is already set to mode 1\n" );
                return false;
            }

            if ( voteArg == "2" && g_mid_aircontrol.integer == 2 )
            {
                client.printMessage( S_COLOR_RED + "Air control is already set to mode 3\n" );
                return false;
            }

            return true;
        }
        else if ( votename == "noquad" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_noquad.boolean )
            {
                client.printMessage( S_COLOR_RED + "noquad is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_noquad.boolean )
            {
                client.printMessage( S_COLOR_RED + "noquad is already enabled\n" );
                return false;
            }

            return true;
        }
        else if ( votename == "walljump" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_walljump.boolean )
            {
                client.printMessage( S_COLOR_RED + "Wall jumping is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_walljump.boolean )
            {
                client.printMessage( S_COLOR_RED + "Wall jumping is already enabled\n" );
                return false;
            }

            return true;
        }
        else if ( votename == "weakonly" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_weakonly.boolean )
            {
                client.printMessage( S_COLOR_RED + "Weak ammo is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_weakonly.boolean )
            {
                client.printMessage( S_COLOR_RED + "Weak ammo is already enabled\n" );
                return false;
            }

            return true;
        }
        else if ( votename == "enablegl" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_enableGL.boolean )
            {
                client.printMessage( S_COLOR_RED + "Grenade Launcher is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_enableGL.boolean )
            {
                client.printMessage( S_COLOR_RED + "Grenade Launcher is already enabled\n" );
                return false;
            }

            return true;
        }

        else if ( votename == "healtharmor" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( match.getState() == MATCH_STATE_PLAYTIME )
            {
                client.printMessage( S_COLOR_YELLOW + votename + S_COLOR_RED + " cannot be voted on during a match.\n" );
                return false;
            }
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_hpap.boolean )
            {
                client.printMessage( S_COLOR_RED + "Health and Armor is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_hpap.boolean )
            {
                client.printMessage( S_COLOR_RED + "Health and Armor is already enabled\n" );
                return false;
            }

            return true;
        }

        else if ( votename == "spawnrape" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_spawnrape.boolean )
            {
                client.printMessage( S_COLOR_RED + "Spawn raping is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_spawnrape.boolean )
            {
                client.printMessage( S_COLOR_RED + "Spawn raping is already enabled\n" );
                return false;
            }

            return true;
        }

        else if ( votename == "knockback" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires at least one argument\n" );
                return false;
            }

            //int value = voteArg.toInt();
            if ( voteArg != "1" && voteArg != "0" )
            {
                client.printMessage( "Callvote " + votename + " expects a 1 or a 0 as argument\n" );
                return false;
            }
            if ( voteArg == "0" && !g_mid_knockback.boolean )
            {
                client.printMessage( S_COLOR_RED + "Knockback boost is already disabled\n" );
                return false;
            }

            if ( voteArg == "1" && g_mid_knockback.boolean )
            {
                client.printMessage( S_COLOR_RED + "Knockback boost is already enabled\n" );
                return false;
            }

            return true;
        }
        //Jerm's begin
        else if ( votename == "team_midair" )
        {
            String voteArg = argsString.getToken( 1 );
            if ( voteArg.len() < 1 )
            {
                client.printMessage( "Callvote " + votename + " requires one argument\n" );
                client.printMessage( "Current: " + voteArg + "\n" );
                return false;
            }

            if ( voteArg == g_mid_team.string )
            {
                client.printMessage( S_COLOR_RED + "Team_midair is already " + g_mid_team.integer + "\n" );
                return false;
            }
            
            return true;
        }
        //Jerm's end

        client.printMessage( "Unknown callvote " + votename + "\n" );
        return false;
    }
    else if ( cmdString == "callvotepassed" )
    {
        String votename = argsString.getToken( 0 );

        if ( votename == "aircontrol" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
            {
                if ( argsString.getToken( 1 ).toInt() == 1 )
                    g_mid_aircontrol.set( 1 );

                if ( argsString.getToken( 1 ).toInt() == 2 )
                    g_mid_aircontrol.set( 2 );
            }
            else
                g_mid_aircontrol.set( 0 );
        }
        else if ( votename == "noquad" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_noquad.set( 1 );
            else
                g_mid_noquad.set( 0 );
        }
        else if ( votename == "walljump" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_walljump.set( 1 );
            else
                g_mid_walljump.set( 0 );
        }
        else if ( votename == "weakonly" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_weakonly.set( 1 );
            else
                g_mid_weakonly.set( 0 );
        }
        else if ( votename == "enablegl" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_enableGL.set( 1 );
            else
                g_mid_enableGL.set( 0 );
        }

        else if ( votename == "healtharmor" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_hpap.set( 1 );
            else
                g_mid_hpap.set( 0 );
        }

        else if ( votename == "spawnrape" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
                g_mid_spawnrape.set( 1 );
            else
                g_mid_spawnrape.set( 0 );
        }

        else if ( votename == "knockback" )
        {
            if ( argsString.getToken( 1 ).toInt() > 0 )
            {
                g_mid_knockback.set( 1 );
                G_CmdExecute( "g_knockback_scale " + g_mid_kbscale.value + "\n" );
            }
            else
            {
                g_mid_knockback.set( 0 );
                G_CmdExecute( "g_knockback_scale 1\n" );
            }
        }
        
        //Jerm's begin
        else if ( votename == "team_midair" )
        {
            if ( argsString.getToken( 1 ).toInt() < 2 )
                g_mid_team.set( 1 );
            else
                g_mid_team.set( argsString.getToken( 1 ).toInt() );

			setupTeamMidair(false);
        }
        //Jerm's end

    }
    else if ( cmdString == "ruleset" )
    {
        G_PrintMsg( client.getEnt(), MIDAIR_DisplayRuleset() );
        return true;
    }

    return false;
}

// When this function is called the weights of items have been reset to their default values,
// this means, the weights *are set*, and what this function does is scaling them depending
// on the current bot status.
// Player, and non-item entities don't have any weight set. So they will be ignored by the bot
// unless a weight is assigned here.
bool GT_UpdateBotStatus( Entity @ent )
{
    return GENERIC_UpdateBotStatus( ent );
}

// select a spawning point for a player
Entity @GT_SelectSpawnPoint( Entity @self )
{
//    return GENERIC_SelectBestRandomSpawnPoint( self, "info_player_deathmatch" );
    return GENERIC_SelectBestRandomSpawnPoint( null, "info_player_deathmatch" );
}

String @GT_ScoreboardMessage( uint maxlen )
{
    String scoreboardMessage = "";
    String entry;
    Team @team;
    Entity @ent;
    int i, t, readyIcon;

    for ( t = TEAM_ALPHA; t < GS_MAX_TEAMS; t++ )
    {
        @team = @G_GetTeam( t );

        // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
        entry = "&t " + t + " " + team.stats.score + " " + team.ping + " ";
		
		if ( scoreboardMessage.len() + entry.len() < maxlen )
			scoreboardMessage += entry;

        for ( i = 0; @team.ent( i ) != null; i++ )
        {
            @ent = @team.ent( i );

            if ( ent.client.isReady() )
                readyIcon = prcYesIcon;
            else
                readyIcon = 0;

            int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;
			

            // "AVATAR Name Clan Score Frags TKs Ping R"
            // Team Kill added in scoreboard
            entry = "&p " + playerID + " " + playerID + " "
                    + ent.client.clanName + " "
                    + ent.client.stats.score + " "
                    + ent.client.stats.frags + " "
                    + ent.client.stats.suicides + " "
                    + ent.client.stats.teamFrags + " "
                    + ent.client.ping + " "
                    + readyIcon + " ";

            if ( scoreboardMessage.len() + entry.len() < maxlen )
                scoreboardMessage += entry;
        }
    }

    return scoreboardMessage;
}

// Some game actions trigger score events. These are events not related to killing
// oponents, like capturing a flag
void GT_ScoreEvent( Client @client, const String &in score_event, const String &in args )
{
    if ( score_event == "dmg" )
    {
    }
    else if ( score_event == "kill" )
    {
        Entity @attacker = null;

        if ( @client != null )
            @attacker = @client.getEnt();

        int arg1 = args.getToken( 0 ).toInt();
        int arg2 = args.getToken( 1 ).toInt();

        MIDAIR_playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );
    }
    else if ( score_event == "award" )
    {
    }
}

// a player is being respawned. This can happen from several ways, as dying, changing team,
// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
void GT_PlayerRespawn( Entity @ent, int old_team, int new_team )
{
    // rename the team to the player name
    if ( old_team != new_team )
    {
    }

    if ( ent.isGhosting() )
        return;

    if ( gametype.isInstagib )
    {
        ent.client.inventoryGiveItem( WEAP_INSTAGUN );
        ent.client.inventorySetCount( AMMO_INSTAS, 1 );
        ent.client.inventorySetCount( AMMO_WEAK_INSTAS, 1 );
    }
    else
    {
        Item @item;
        Item @ammoItem;

        // the gunblade can't be given (because it can't be dropped)
        ent.client.inventorySetCount( WEAP_GUNBLADE, 1 );

        @item = @G_GetItem( WEAP_GUNBLADE );

        @ammoItem = @G_GetItem( item.ammoTag );
        if ( @ammoItem != null )
            ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

        @ammoItem = @G_GetItem( item.weakAmmoTag );
        if ( @ammoItem != null )
            ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

        // reset kills
        Player @a = GetClientPlayer( ent.client );
                    a.reset();
                    ent.client.armor = 100;     // fixes the no HP bug - TEMPORARY FIX

        // WARMUP SHIT THAT WE DONT NEED
        /*
        if ( match.getState() <= MATCH_STATE_WARMUP )
        {
            for ( int i = WEAP_GUNBLADE + 1; i < WEAP_TOTAL; i++ )
            {
                if ( i == WEAP_INSTAGUN ) // dont add instagun...
                    continue;

                ent.client.inventoryGiveItem( i );

                @item = @G_GetItem( i );

                @ammoItem = @G_GetItem( item.ammoTag );
                if ( @ammoItem != null )
                    ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

                @ammoItem = @G_GetItem( item.weakAmmoTag );
                if ( @ammoItem != null )
                    ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );
            }

            // give him 2 YAs
            ent.client.inventoryGiveItem( ARMOR_YA );
            ent.client.inventoryGiveItem( ARMOR_YA );
        }
        */
    }

    // rocket launcher shiz ---- IMPORTANT -- FLAGGED
    if ( ent.client.inventoryCount( WEAP_ROCKETLAUNCHER ) < 1 )
    {
        ent.client.inventoryClear();
        ent.client.inventoryGiveItem( WEAP_ROCKETLAUNCHER );

        if( !g_mid_noquad.boolean )
            ent.client.inventoryGiveItem( POWERUP_QUAD );
        // dont think we really need this check, but just in case :>
        // checks to see if the RL is equippable or whateverz
        if ( ent.client.canSelectWeapon( WEAP_ROCKETLAUNCHER ) )
            ent.client.selectWeapon( WEAP_ROCKETLAUNCHER );

        if ( g_mid_enableGL.boolean )
        {
            ent.client.inventoryGiveItem( WEAP_GRENADELAUNCHER );
            ent.client.inventorySetCount( AMMO_WEAK_GRENADES, 1 );
        }
    }

    // select rocket launcher if available
    if ( ent.client.canSelectWeapon( WEAP_ROCKETLAUNCHER ) )
        ent.client.selectWeapon( WEAP_ROCKETLAUNCHER );
    else
        ent.client.selectWeapon( -1 ); // auto-select best weapon in the inventory

    // add a teleportation effect
    ent.respawnEffect();
}

// Thinking function. Called each frame
bool firstThink = true;
void GT_ThinkRules()
{

	if(firstThink)
	{
		firstThink = false;
		dropOutFromQueue();
		return;
	}

    if ( match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished() )
    {
        if ( !match.checkExtendPlayTime() )
            match.launchState( match.getState() + 1 );
    }

    GENERIC_DetectTeamsAndMatchNames();

    if ( match.getState() >= MATCH_STATE_POSTMATCH )
        return;

    float maxArmor = G_GetItem( ARMOR_RA ).quantity;

    float maxQuad = G_GetItem( POWERUP_QUAD ).quantity;

    // checks for knockback callvote :P
    if ( g_mid_knockback.boolean && knockScale.value != g_mid_kbscale.value )
        G_CmdExecute( "g_knockback_scale " + g_mid_kbscale.value + "\n" );
    if ( !g_mid_knockback.boolean && knockScale.value != float( 1.0 ) )
        G_CmdExecute( "g_knockback_scale 1\n" );

    // check maxHealth rule and max armor rule
    // EDIT: keeps giving ammo now, code at top
    for ( int i = 0; i < maxClients; i++ )
    {
        Entity @ent = @G_GetClient( i ).getEnt();
        if ( ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR )
        {

            // enable and disabling quad damage
            if( !g_mid_noquad.boolean )
            {
                if( ent.client.inventoryCount( POWERUP_QUAD ) <= maxQuad )
                    ent.client.inventorySetCount( POWERUP_QUAD, maxQuad );
            }

            if( g_mid_noquad.boolean && ent.client.inventoryCount( POWERUP_QUAD ) >= 1 )
                ent.client.inventorySetCount( POWERUP_QUAD, 0 );



            // PLEASE EXCUSE MY CRUDE CODE - MOONSHIELD IS RUSHING ME, UMAD MOONSHIELD?
            if( !g_mid_noquad.boolean && ent.client.inventoryCount( POWERUP_QUAD ) <= 0 )
                ent.client.inventoryGiveItem( POWERUP_QUAD );

            if( !g_mid_noquad.boolean )
                ent.client.inventorySetCount( POWERUP_QUAD, maxQuad );

            // weak ammo only
            if ( g_mid_weakonly.boolean )
            {
                if ( ent.client.inventoryCount( AMMO_WEAK_ROCKETS ) < 10
                     || ent.client.inventoryCount( AMMO_ROCKETS ) > 0 )
                {
                    ent.client.inventorySetCount( AMMO_ROCKETS, 0 );
                    ent.client.inventorySetCount( AMMO_WEAK_ROCKETS, 10 );
                }
            }

            // strong ammo
            if ( !g_mid_weakonly.boolean )
            {
                if ( ent.client.inventoryCount( AMMO_ROCKETS ) <= 10 )
                    ent.client.inventorySetCount( AMMO_ROCKETS, 10 );
            }

            // grenade launcher stuffs
            if ( g_mid_enableGL.boolean )
            {
                // gives grenade launcher
                if ( ent.client.inventoryCount( WEAP_GRENADELAUNCHER ) < 1 )
                {
                    ent.client.inventoryGiveItem( WEAP_GRENADELAUNCHER );
                    ent.client.inventorySetCount( AMMO_WEAK_GRENADES, 1 );
                }

                Player @p = GetClientPlayer( ent.client );
                    if ( p.lastGrenade == 0 && ent.client.inventoryCount( AMMO_WEAK_GRENADES ) < 1 )
                        p.lastGrenade = p.MakeTime( 3 );

                if ( ent.client.inventoryCount( AMMO_WEAK_GRENADES ) < 1
                     || ent.client.inventoryCount( AMMO_GRENADES ) > 0 )
                {
                    ent.client.inventorySetCount( AMMO_GRENADES, 0 );

                    if ( p.lastGrenade <= levelTime )
                    {
                        ent.client.inventorySetCount( AMMO_WEAK_GRENADES, 1 );
                        p.lastGrenade = 0;
                    }
                }
            }

            if ( !g_mid_enableGL.boolean && ent.client.inventoryCount( WEAP_GRENADELAUNCHER ) > 0 )
            {
                // gets rid of the GL and ammo
                ent.client.inventorySetCount( WEAP_GRENADELAUNCHER, 0 );
                ent.client.inventorySetCount( AMMO_WEAK_GRENADES, 0 );

                // makes the user switch to RL
                if ( ent.client.canSelectWeapon( WEAP_ROCKETLAUNCHER ) )
                    ent.client.selectWeapon( WEAP_ROCKETLAUNCHER );
            }

            // this stuff below has do to with g_mid_height and checking for the ground below you
            Trace ln;
            Vec3 end, start, mins( 0, 0, 0 ), maxs( 0, 0, 0 );

            start = end = ent.origin;   // getting origin vectors
            end.z -= g_mid_height.integer;   // sets z endpoint

            if ( !ln.doTrace( start, mins, maxs, end, ent.entNum, MASK_SOLID ) )
            {

                // if hp/ap is turned off
                if ( !g_mid_hpap.boolean )
                {
                    Player @p = GetClientPlayer( ent.client );

                    if ( ent.health > 1 )
                    {
                        ent.health = 1;
                        p.hp = 100;
                    }

                    if ( ent.client.armor > 0 )
                    {
                        ent.client.armor = 0;
                        p.ap = 100;
                    }
                }

                // if hp/ap is turned on
                if ( g_mid_hpap.boolean )
                    {
                        // dont know for now?
                        Player @p = GetClientPlayer( ent.client );

                        if ( ent.health > 100 )
                            ent.health = p.hp;
                        if ( ent.client.armor > 100 )
                            ent.client.armor = p.ap;
                    }

                // disables wall jumping if its disabled by server or vote
                if ( !g_mid_walljump.boolean )
                    ent.client.set_pmoveFeatures( ent.client.pmoveFeatures & ~int( PMFEAT_WALLJUMP ) );


                //!**************IMPORTANT*******************!//
                /*      deals with player air control         */
                PlayerThinkControl( ent );
                //!******************************************!//

            }

            if ( ln.doTrace( start, mins, maxs, end, ent.entNum, MASK_SOLID ) )
            {
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures | int( PMFEAT_AIRCONTROL ) );
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures | int( PMFEAT_WALLJUMP ) );
                ent.client.set_pmoveMaxSpeed( P_WALK_SPEED );    // resets moving speed

                if( !g_mid_hpap.boolean )
                {
                    if( ent.health < 999 && ent.health > 0)
                        ent.health = 999;

                    if( ent.client.armor < 999 )
                        ent.client.armor = 999;
                }

                 //if hp/ap is turned on
                if ( g_mid_hpap.boolean )
                {
                    // dont know for now?
                        Player @p = GetClientPlayer( ent.client );
                        if ( p.hp > ent.health && ent.health > 0)
                            p.hp = ent.health;

                        if ( p.ap > ent.client.armor && ent.client.armor > 0 )
                            p.ap = ent.client.armor;

                        if ( ent.health > 0 )
                            ent.health = 999;

                        if ( ent.client.armor > 0 )
                            ent.client.armor = 999;
                }
            }

            // HP/AP bleeding - DO NOT WANT >:|
            /*
            if ( ent.health > ent.maxHealth )
                ent.health -= ( frameTime * 0.001f );

            if ( ent.client.armor > maxArmor )
            {
                float newArmor = ent.client.armor - ( frameTime * 0.001f );
                if ( newArmor < maxArmor )
                    ent.client.armor = maxArmor;
                else
                    ent.client.armor = newArmor;
            }
            */
        }
    }
	

}

// The game has detected the end of the match state, but it
// doesn't advance it before calling this function.
// This function must give permission to move into the next
// state by returning true.
bool GT_MatchStateFinished( int incomingMatchState )
{
    if ( match.getState() <= MATCH_STATE_WARMUP && incomingMatchState > MATCH_STATE_WARMUP
            && incomingMatchState < MATCH_STATE_POSTMATCH )
        match.startAutorecord();

    if ( match.getState() == MATCH_STATE_POSTMATCH )
        match.stopAutorecord();

    // check maxHealth rule
    for ( int i = 0; i < maxClients; i++ )
    {
        Entity @ent = @G_GetClient( i ).getEnt();
        if ( ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR )
        {
            if ( ent.health > ent.maxHealth )
                ent.health -= ( frameTime * 0.001f );
        }
    }

    return true;
}

// the match state has just moved into a new state. Here is the
// place to set up the new state rules
void GT_MatchStateStarted()
{
    switch ( match.getState() )
    {
    case MATCH_STATE_WARMUP:
        gametype.pickableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        GENERIC_SetUpWarmup();
		setUpClients(true);
        break;

    case MATCH_STATE_COUNTDOWN:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        GENERIC_SetUpCountdown();
        break;

    case MATCH_STATE_PLAYTIME:
        gametype.pickableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        MIDAIR_SetUpMatch();
        break;

    case MATCH_STATE_POSTMATCH:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        GENERIC_SetUpEndMatch();
        break;

    default:
        break;
    }
}

// the gametype is shutting down cause of a match restart or map change
void GT_Shutdown()
{
    //!**************IMPORTANT*************!//
    //Jerm's: better use .reset to set default value
    //if( knockScale.defaultString() != knockScale.string )
        knockScale.reset();
}

// The map entities have just been spawned. The level is initialized for
// playing, but nothing has yet started.
void GT_SpawnGametype()
{
}

// Important: This function is called before any entity is spawned, and
// spawning entities from it is forbidden. If you want to make any entity
// spawning at initialization do it in GT_SpawnGametype, which is called
// right after the map entities spawning.

void GT_InitGametype()
{
    gametype.title = "Midair";
    gametype.version = "0.5" ;
    gametype.author = "THRESHER #warsow.na" ;

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
                 + "// Author: " + gametype.author + "\n"
                 + "// Release: " + gametype.version + "\n"
                 + "// This config will be executed each time the gametype is started\n"
                 + "\n\n// map rotation\n"
                 + "set g_maplist \"\" // list of maps in automatic rotation\n"
                 + "set g_maprotation \"0\"   // 0 = same map, 1 = in order, 2 = random\n"
                 + "\n// game settings\n"
                 + "set g_scorelimit \"0\"\n"
                 + "set g_timelimit \"3\"\n"
                 + "set g_warmup_enabled \"1\"\n"
                 + "set g_warmup_timelimit \"3\"\n"
                 + "set g_match_extendedtime \"0\"\n"
                 + "set g_allow_falldamage \"0\"\n"
                 + "set g_allow_selfdamage \"0\"\n"
                 + "set g_allow_teamdamage \"1\"\n"
                 + "set g_allow_stun \"1\"\n"
                 + "set g_teams_maxplayers \"1\"\n"
                 + "set g_teams_allow_uneven \"0\"\n"
                 + "set g_countdown_time \"5\"\n"
                 + "set g_maxtimeouts \"-1\" // -1 = unlimited\n"
                 + "set g_challengers_queue \"1\"\n"
                 + "\n// gametype settings\n"
                 + "set g_mid_aircontrol \"0\" // 0 = no control in air 1 = full air control 2 = maintain momentum with no aircontrol\n"
                 + "set g_mid_noquad \"1\"   // turn quad on|off, votable\n"
                 + "set g_mid_weakonly \"0\" // turn on weak ammo only, votable\n"
                 + "set g_mid_height \"172\" // 172 is default height for midair, used to be 152\n"
                 + "set g_mid_walljump \"0\" // enables/disables wall jumping while in midair, votable\n"
                 + "set g_mid_hpap \"0\"     // enables/disables 100 hp and 100 armor at spawn, votable\n"
                 + "set g_mid_enablegl \"0\" // enables/disables the grenade launcher, votable\n"
                 + "set g_mid_spawnrape \"1\" // enables/disables air movement at spawn, votable\n"
                 + "set g_mid_kbscale \"2.8\" // scaled knockback when g_mid_knockback is enabled\n"
                 + "set g_mid_knockback \"1\" // turns g_mid_kbscale on|off, votable\n"
                 + "set g_mid_team \"1\"      // 1: toggles Challengers queue ON and set maxteamplayers to 1, n: toggles Challengers queue OFF and set maxteamplayers to n\n"
                 + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

    // loading custom map configs
    if ( G_FileExists( "configs/server/maps/" + mapName.string + "_mid.cfg" ) )
    {
        G_CmdExecute( "exec configs/server/maps/" + mapName.string + "_mid.cfg" );
        G_Print( S_COLOR_GREEN + "custom map configuration load successful\n" );
    }
    else if ( !G_FileExists( "configs/server/maps/" + mapName.string + "_mid.cfg" ) )
    {
        G_Print( S_COLOR_RED + "custom map configuration file unavailable\n" );
    }

    gametype.spawnableItemsMask = ( IT_WEAPON | IT_AMMO | IT_ARMOR | IT_HEALTH );
    //if ( gametype.isInstagib() )
        gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);

    gametype.respawnableItemsMask = gametype.spawnableItemsMask ;
    gametype.dropableItemsMask = gametype.spawnableItemsMask;
    gametype.pickableItemsMask = ( gametype.spawnableItemsMask | gametype.dropableItemsMask );

    gametype.isTeamBased = true;
    gametype.isRace = false;
    
    //Jerm's begin
	
	setupTeamMidair(true);
	
    //Jerm's end
         
    gametype.ammoRespawn = 20;
    gametype.armorRespawn = 25;
    gametype.weaponRespawn = 15;
    gametype.healthRespawn = 25;
    gametype.powerupRespawn = 90;
    gametype.megahealthRespawn = 20;
    gametype.ultrahealthRespawn = 40;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = false;
    gametype.shootingDisabled = false;
    gametype.infiniteAmmo = false;
    gametype.canForceModels = true;
    gametype.canShowMinimap = false;
    gametype.teamOnlyMinimap = false;

    gametype.spawnpointRadius = 256;

    if ( gametype.isInstagib )
        gametype.spawnpointRadius *= 2;

    // set spawnsystem type
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );

    // define the scoreboard layout
    //Team Kill added in the layout
    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%a l1 %n 112 %s 52 %i 42 %i 40 %i 40 %i 40 %l 40 %p 18" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "AVATAR Name Clan Sco Fra Sui TK Ping R" );

    // precache images that can be used by the scoreboard
    prcYesIcon = G_ImageIndex( "gfx/hud/icons/vsay/yes" );
    prcShockIcon = G_ImageIndex( "gfx/hud/icons/powerup/quad" );
    prcShellIcon = G_ImageIndex( "gfx/hud/icons/powerup/warshell" );

    // add commands
    G_RegisterCommand( "drop" );
    G_RegisterCommand( "gametype" );
    G_RegisterCommand( "mapnum" );
    G_RegisterCommand( "ruleset" );

    //!************************************* IMPORTANT ******************************************!//
    //!-----------------------------------CALLVOTE OPTIONS---------------------------------------!//
    //!******************************************************************************************!//
    G_RegisterCallvote( "aircontrol", "<0|1|2>", "integer", "0: no aircontrol\n- 1: full aircontrol\n- 2: no aircontrol, maintains momentum");
    G_RegisterCallvote( "noquad", "<1 or 0>", "bool", "Disables/Enables the quad powerup." );
    G_RegisterCallvote( "enablegl", "<1 or 0>", "bool", "Enables/Disables the grenade launcher.");
    G_RegisterCallvote( "healtharmor", "<1 or 0>", "bool", "Enables/Disables 100 HP and 100 Armor at spawn." );
    G_RegisterCallvote( "weakonly", "<1 or 0>", "bool", "Enables/Disables weak ammo only." );
    G_RegisterCallvote( "walljump", "<1 or 0>", "bool", "Enables/Disables wall jumping when you are at frag height" );
    //G_RegisterCallvote( "fragheight", "<25 - 3200>", "Sets the height that the player must be in order to frag, 152 is default" );
    G_RegisterCallvote( "spawnrape", "<1 or 0>", "bool"," Disables/Enables spawn air control" );
    G_RegisterCallvote( "knockback", "<1 or 0>", "bool"," Sets the servers defined knockback boost on, default 2.8" );
    G_RegisterCallvote( "team_midair", "<number>", "integer", "1: toggles Challengers queue ON and set maxteamplayers to 1\n- n: toggles Challengers queue OFF and set maxteamplayers to n" );
            
    G_Print( "Gametype '" + gametype.title + "' initialized\n" );
    G_Print( MIDAIR_DisplayRuleset() );

}
