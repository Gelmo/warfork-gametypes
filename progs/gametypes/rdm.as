//  Raging Deathmatch is an alternative deathmatch gametype for Warfork.
//  The only distinction from the default deathmatch is that the score is
//  measured not by frags, but by a numeric equivalent of the beauty of
//  the shots.
//
//  Copyright (C) 2018-2019 Nicholas Laramie <nick65irene@gmail.com>
//  Copyright (C) 2011-2016 Vitaly Minko <vitaly.minko@gmail.com>
//  Copyright (C) 2002-2009 The Warsow devteam
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Version 0.7 from 1 Oct 2019
//  Based on the DeathMatch gametype

// Do we have builtin math constants?
const float pi = 3.14159265f;

Vec3[] rdmVelocities( maxClients );
uint[] rdmTimes( maxClients );
bool[] isWelcomed( maxClients );
uint rdmEndTime = 0;

Cvar rdmDebug( "rdm_debug", "1", CVAR_ARCHIVE );

///*****************************************************************
/// RDM FUNCTIONS
///*****************************************************************

int RDM_round( float f )
{
    if ( abs( f - floor( f ) ) < 0.5f )
        return int( f );
    else
        return int( f + f / abs( f ) );
}

float RDM_min( float a, float b )
{
    return ( a >= b ) ? b : a;
}

String RDM_getTimeString( int num )
{
    String minsString, secsString;
    String notime = "--:--";
    uint mtime, stime, min, sec;

    switch ( match.getState() )
    {
    case MATCH_STATE_WARMUP:
    case MATCH_STATE_COUNTDOWN:
        return notime;

    case MATCH_STATE_PLAYTIME:
        mtime = levelTime - rdmTimes[ num ];
        break;

    case MATCH_STATE_POSTMATCH:
    case MATCH_STATE_WAITEXIT:
        if ( rdmEndTime > 0 )
        {
            mtime = rdmEndTime - rdmTimes[ num ];
            break;
        }

    default:
        return notime;
    }

    stime = RDM_round( mtime / 1000.0f );
    min = stime / 60;
    sec = stime % 60;

    minsString = ( min >= 10 ) ? "" + min : "0" + min;
    secsString = ( sec >= 10 ) ? "" + sec : "0" + sec;

    return minsString + ":" + secsString;
}

float RDM_getDistance( Entity @a, Entity @b )
{
    return a.origin.distance( b.origin );
}

float RDM_getAngle( Vec3 a, Vec3 b )
{   
    Vec3 my_a = a;
    Vec3 my_b = b;

    if ( my_a.length() == 0 || my_b.length() == 0 )
        return 0;
  
    my_a.normalize();
    my_b.normalize();

    return abs( acos( my_a.x * my_b.x + my_a.y * my_b.y + my_a.z * my_b.z ) );
}

float RDM_getAngleFactor ( float angle )
{
    const float minAcuteFactor = 0.15f;
    const float minObtuseFactor = 0.30f;

    return ( angle < pi / 2.0f ) ?
        minAcuteFactor + ( 1.0f - minAcuteFactor ) * sin( angle ) :
        minObtuseFactor + ( 1.0f - minObtuseFactor ) * sin( angle );
}

Vec3 RDM_getVector( Entity @a, Entity @b )
{
    Vec3 ao;
    Vec3 bo;

    ao = a.origin;
    bo = b.origin;
    bo.x -= ao.x;
    bo.y -= ao.y;
    bo.z -= ao.z;

    return bo;
}

float RDM_getAnticampFactor ( float normalizedVelocity )
{
    // How fast does the factor grow?
    const float scale = 12.0f;

    return ( atan( scale * ( normalizedVelocity - 1.0f ) ) + pi / 2.0f ) / pi;
}

int RDM_calculateScore( Entity @target, Entity @attacker )
{
    // Default score for a "normal" shot
    const float defScore = 100.0f;
    // Normal speed
    const float normVelocity = 600.0f;
    // Normal distance
    const float normDist = 800.0f;

    Vec3 directionAt = RDM_getVector( attacker, target );
    Vec3 directionTa = RDM_getVector( target, attacker );

    /* Projection of the attacker's velocity relative to ground to the flat
     * surface that is perpendicular to the vector from the attacker
     * to the target */
    Vec3 velocityA = attacker.velocity;
    float angleA = RDM_getAngle( velocityA, directionAt );
    float projectionA = RDM_getAngleFactor( angleA ) * velocityA.length();

    /* Anti-camping dumping - we significantly decrease projection if the
     * attacker's velocity is lower than the normVelocity */
    float anticampFactor = RDM_getAnticampFactor( velocityA.length() / normVelocity );

    /* Projection of the target's velocity relative to the ground to the flat
     * surface that is perpendicular to the vector from the target
     * to the attacker */
    Vec3 velocityTg = rdmVelocities[ target.playerNum ];
    float angleTg = RDM_getAngle( velocityTg, directionTa );
    float projectionTg = RDM_getAngleFactor( angleTg ) * velocityTg.length();

    /* Projection of the target's velocity relative to the attacker to the flat
     * surface that is perpendicular to the vector from the target
     * to the attacker */
    Vec3 velocityTa = velocityTg - attacker.velocity;
    float angleTa = RDM_getAngle( velocityTa, directionTa );
    float projectionTa = RDM_getAngleFactor( angleTa ) * velocityTa.length();

    /* Choose minimal projection */
    float projectionT = RDM_min( projectionTg, projectionTa );

    float score = defScore
                * anticampFactor
                * pow( projectionA / normVelocity, 2.0f )
                * ( 1.0f + projectionT / normVelocity )
                * ( RDM_getDistance( attacker, target ) / normDist );

    if ( rdmDebug.boolean )
        G_Print( S_COLOR_BLUE + "DEBUG:" +
                 " ACF = " + anticampFactor +
                 " Va = " + velocityA.length() +
                 " Aa = " + int( angleA * 180.0f / pi ) +
                 " Vtg = " + velocityTg.length() +
                 " Atg = " + int( angleTg * 180.0f / pi ) +
                 " Vta = " + velocityTa.length() +
                 " Ata = " + int( angleTa * 180.0f / pi ) +
                 " D = " + RDM_getDistance( attacker, target ) +
                 " S = " + score +
                 "\n" );

    return int( score );
}

// a player has just died. The script is warned about it so it can account scores
void RDM_playerKilled( Entity @target, Entity @attacker, Entity @inflicter )
{
    if ( match.getState() != MATCH_STATE_PLAYTIME )
        return;

    if ( @target.client == null )
        return;

    // punishment for suicide
    if ( @attacker == null || attacker.playerNum == target.playerNum )
        target.client.stats.addScore( -500 );

    // update player score
    if ( @attacker != null && @attacker.client != null )
    {
       int score = RDM_calculateScore( target, attacker );
       attacker.client.stats.addScore( score );
       if ( score >= 500 && score < 1000 )
       {
           attacker.client.addAward("Nice shot");
           G_PrintMsg( null,
                       attacker.client.name + " made a nice shot\n" );
       }
       if ( score >= 1000 )
       {
           attacker.client.addAward(S_COLOR_RED + "!!! A W E S O M E !!!");
           G_PrintMsg( null,
                       attacker.client.name + S_COLOR_RED + " is AWESOME!\n" );
       }
    }
}

///*****************************************************************
/// MODULE SCRIPT CALLS
///*****************************************************************

bool GT_Command( Client @client, const String &cmdString, const String &argsString, int argc )
{
    if ( cmdString == "gametype" )
    {
        String response = "";
        Cvar fs_game( "fs_game", "", 0 );
        String manifest = gametype.manifest;

        response = "\n"
                 + "Gametype " + gametype.name + " : " + gametype.title + "\n"
                 + "----------------\n"
                 + "Version: " + gametype.version + "\n"
                 + "Author: " + gametype.author + "\n"
                 + "Mod: " + fs_game.string
                 + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n"
                 + "Type `help' for more information about the gametype\n"
                 + "----------------\n";

        G_PrintMsg( client.getEnt(), response );
        return true;
    }
    else if ( cmdString == "help" )
    {        
        String response = "";
        response = S_COLOR_WHITE
                 + "--------------- Information about " + S_COLOR_RED + "Raging"
                 + S_COLOR_WHITE + " DeathMatch ---------------\n"
                 + "The score you get depends on the following parameters:\n"
                 + "1. Your speed.\n"
                 + "2. Speed of your target.\n"
                 + "3. Distance between you and your target.\n"
                 + "\n"
                 + "The harder it is to hit the target (higher speeds, longer distance),"
                 + " the higher score you'll get. If your speed is very low, then your"
                 + " score gets significantly dumped (anti-camper protection).\n"
                 + "\n"
                 + "See " + S_COLOR_YELLOW + "vminko.org/rdm" + S_COLOR_WHITE
                 + " for details of how the score is calculated.\n"
                 + "Have fun!\n"
                 + S_COLOR_WHITE
                 + "-----------------------------------------------------------------\n";
        G_PrintMsg( client.getEnt(), response );
        return true;
    }

    return false;
}

// When this function is called the weights of items have been reset to their default values,
// this means, the weights *are set*, and what this function does is scaling them depending
// on the current bot status.
// Player, and non-item entities don't have any weight set. So they will be ignored by the bot
// unless a weight is assigned here.
bool GT_UpdateBotStatus( Entity @self )
{
    return GENERIC_UpdateBotStatus( self );
}

// select a spawning point for a player
Entity @GT_SelectSpawnPoint( Entity @self )
{
    return GENERIC_SelectBestRandomSpawnPoint( self, "info_player_deathmatch" );
}

String @GT_ScoreboardMessage( uint maxlen )
{
    String scoreboardMessage = "";
    String entry;
    Team @team;
    Entity @ent;
    int i;

    @team = @G_GetTeam( TEAM_PLAYERS );

    // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
    entry = "&t " + int( TEAM_PLAYERS ) + " " + team.stats.score + " 0 ";
    if ( scoreboardMessage.len() + entry.len() < maxlen )
        scoreboardMessage += entry;

    for ( i = 0; @team.ent( i ) != null; i++ )
    {
        @ent = @team.ent( i );

        int playerID =
            ( ent.isGhosting()
              && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ?
            -( ent.playerNum + 1 ) : ent.playerNum;

        entry = "&p " + playerID + " "
              + ent.client.clanName + " "
              + ent.client.stats.score + " "
              + RDM_getTimeString( ent.playerNum ) + " "
              + ent.client.ping + " "
                + ( ent.client.isReady() ? "1" : "0" ) + " ";

        if ( scoreboardMessage.len() + entry.len() < maxlen )
            scoreboardMessage += entry;
    }

    return scoreboardMessage;
}

// Some game actions trigger score events. These are events not related to killing
// oponents, like capturing a flag
void GT_ScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( score_event == "connect" )
    {
        isWelcomed[ client.getEnt().playerNum ] = false;
    }
    else if ( score_event == "disconnect" )
    {
    }
    else if ( score_event == "dmg" )
    {
    }
    else if ( score_event == "kill" )
    {
        Entity @attacker = null;

        if ( @client != null )
            @attacker = @client.getEnt();

        int arg1 = args.getToken( 0 ).toInt();
        int arg2 = args.getToken( 1 ).toInt();

        // target, attacker, inflictor
        RDM_playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );
    }
    else if ( score_event == "award" )
    {
    }
}

// a player is being respawned. This can happen from several ways, as dying, changing team,
// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
void GT_PlayerRespawn( Entity @ent, int old_team, int new_team )
{
    if ( new_team == TEAM_SPECTATOR )
        return;

    if ( old_team == TEAM_SPECTATOR
         && new_team != TEAM_SPECTATOR
         && match.getState() == MATCH_STATE_PLAYTIME )
    {
        rdmTimes[ ent.playerNum ] = levelTime;
    }

    if ( new_team != TEAM_SPECTATOR && !isWelcomed[ ent.playerNum ] )
    {
        String welcome = "";
        welcome = S_COLOR_WHITE
                + "Welcome to " + S_COLOR_RED + "Raging" + S_COLOR_WHITE + " DeathMatch!\n"
                + "The basic rule is that you have to move fast to get decent score.\n"
                + "Type " + S_COLOR_YELLOW + "help" + S_COLOR_WHITE + " in"
                + " the console for details.\n";
        G_PrintMsg( ent, welcome );
        isWelcomed[ ent.playerNum ] = true;
    }

    ent.client.inventoryGiveItem( WEAP_INSTAGUN );
    ent.client.inventorySetCount( AMMO_INSTAS, 1 );
    ent.client.inventorySetCount( AMMO_WEAK_INSTAS, 1 );

    // auto-select best weapon in the inventory
    ent.client.selectWeapon( -1 ); 

    // add a teleportation effect
    ent.respawnEffect();
}

// Thinking function. Called each frame
void GT_ThinkRules()
{
    if ( match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished() )
        match.launchState( match.getState() + 1 );

    if ( match.getState() >= MATCH_STATE_POSTMATCH )
        return;

    for ( int i = 0; i < maxClients; i++ )
    {
        Entity @ent = @G_GetClient( i ).getEnt();
        if ( ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR )
        {
            rdmVelocities[ ent.playerNum ] = ent.velocity;
        }
    }
}

// The game has detected the end of the match state, but it
// doesn't advance it before calling this function.
// This function must give permission to move into the next
// state by returning true.
bool GT_MatchStateFinished( int incomingMatchState )
{
    if ( match.getState() <= MATCH_STATE_WARMUP
         && incomingMatchState > MATCH_STATE_WARMUP
         && incomingMatchState < MATCH_STATE_POSTMATCH )
        match.startAutorecord();

    if ( incomingMatchState == MATCH_STATE_PLAYTIME )
        for ( int i = 0; i < maxClients; i++ )
            rdmTimes[ i ] = levelTime;

    if ( match.getState() == MATCH_STATE_PLAYTIME &&
         incomingMatchState == MATCH_STATE_POSTMATCH )
        rdmEndTime = levelTime;

    if ( match.getState() == MATCH_STATE_POSTMATCH )
        match.stopAutorecord();

    return true;
}

// the match state has just moved into a new state. Here is the
// place to set up the new state rules
void GT_MatchStateStarted()
{
    switch ( match.getState() )
    {
    case MATCH_STATE_WARMUP:
        GENERIC_SetUpWarmup();
        rdmEndTime = 0;
        break;

    case MATCH_STATE_COUNTDOWN:
        GENERIC_SetUpCountdown();
        break;

    case MATCH_STATE_PLAYTIME:
        GENERIC_SetUpMatch();
        break;

    case MATCH_STATE_POSTMATCH:
        GENERIC_SetUpEndMatch();
        break;

    default:
        break;
    }
}

// the gametype is shutting down cause of a match restart or map change
void GT_Shutdown()
{
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
    gametype.title = "Raging Deathmatch";
    gametype.version = "0.7";
    gametype.author = "Nicholas Laramie";

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
               + "// This config will be executed each time the gametype is started\n"
               + "\n\n// map rotation\n"
               + "set g_instagib \"1\"\n"
               + "set g_instajump \"1\"\n"
               + "set g_instashield \"0\"\n"
               + "set g_maplist \"wfca1 bipbeta2-1\"\n"
               + "set g_maprotation \"0\"   // 0 = same map, 1 = in order, 2 = random\n"
               + "\n// game settings\n"
               + "set g_scorelimit \"0\"\n"
               + "set g_timelimit \"20\"\n"
               + "set g_warmup_enabled \"1\"\n"
               + "set g_warmup_timelimit \"1\"\n"
               + "set g_match_extendedtime \"0\"\n"
               + "set g_allow_falldamage \"0\"\n"
               + "set g_allow_selfdamage \"0\"\n"
               + "set g_allow_teamdamage \"0\"\n"
               + "set g_allow_stun \"1\"\n"
               + "set g_teams_maxplayers \"0\"\n"
               + "set g_teams_allow_uneven \"0\"\n"
               + "set g_countdown_time \"3\"\n"
               + "set g_maxtimeouts \"0\" // -1 = unlimited\n"
               + "set g_challengers_queue \"0\"\n"
               + "set rdm_debug \"0\"\n"
               + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

    if ( !gametype.isInstagib )
    {
        G_Print( S_COLOR_RED + "ERROR: Instagib is disabled!"
                 + " This gametype works only with instagib enabled.\n"
                 + " Failed to initialize the gametype!\n" );
        return;
    }

    gametype.spawnableItemsMask = 0;
    gametype.respawnableItemsMask = 0;
    gametype.dropableItemsMask = 0;
    gametype.pickableItemsMask = 0;

    gametype.isTeamBased = false;
    gametype.isRace = false;
    gametype.hasChallengersQueue = false;
    gametype.maxPlayersPerTeam = 0;

    gametype.spawnpointRadius = 256*2;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = false;
    gametype.shootingDisabled = false;
    gametype.infiniteAmmo = false;
    gametype.canForceModels = true;
    gametype.canShowMinimap = false;
    gametype.teamOnlyMinimap = false;


    // set spawnsystem type
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );

    // define the scoreboard layout
    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 64 %s 64 %l 48 %p 18" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Time Ping R" );

    // init per-client variables
    for ( int i = 0; i < maxClients; i++ )
    {
        rdmVelocities[ i ] = Vec3( 0 );
        rdmTimes[ i ] = 0;
        isWelcomed[ i ] = true;
    }

    // add commands
    G_RegisterCommand( "gametype" );
    G_RegisterCommand( "help" );

    G_Print( "Gametype '" + gametype.title + "' initialized\n" );
}

