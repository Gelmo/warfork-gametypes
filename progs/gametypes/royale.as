/*
Copyright (C) 2009-2010 Chasseur de bots

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

uint brTimelimit1v1;
int brRoundLimit;

Cvar g_br_timelimit1v1( "g_br_timelimit1v1", "60", 0 );

Cvar g_noclass_inventory( "g_noclass_inventory", "gb mg rg gl rl pg lg eb cells shells grens rockets plasma lasers bolts bullets", 0 );
Cvar g_class_strong_ammo( "g_class_strong_ammo", "1 75 20 20 40 125 180 15", 0 ); // GB MG RG GL RL PG LG EB

Cvar g_br_lmsbonus( "g_br_lmsbonus", "1", 0 );
Cvar g_br_roundlimit( "g_br_roundlimit", "10", 0 );

const int BR_ROUNDSTATE_NONE = 0;
const int BR_ROUNDSTATE_PREROUND = 1;
const int BR_ROUNDSTATE_ROUND = 2;
const int BR_ROUNDSTATE_ROUNDFINISHED = 3;
const int BR_ROUNDSTATE_POSTROUND = 4;

int[] brBonusScores( maxClients );
int[] brLMSCounts( maxClients ); // last man standing bonus for each possible player

class cBRRound
{
    int state;
    int numRounds;
    uint roundStateStartTime;
    uint roundStateEndTime;
    int countDown;
	uint minuteLeft;
	int timelimit;
	int players_oneVS;

    cBRRound()
    {
        this.state = BR_ROUNDSTATE_NONE;
        this.numRounds = 0;
        this.roundStateStartTime = 0;
        this.countDown = 0;
		this.minuteLeft = 0;
		this.timelimit = 0;
        
        this.players_oneVS = 0;
    }

    ~cBRRound() {}

    void newGame()
    {
        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = true;
        gametype.countdownEnabled = false;

        // set spawnsystem type to not respawn the players when they die
        for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
            gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_HOLD, 0, 0, true );

        // clear scores

        Entity @ent;
        Team @team;
        int i;

        for ( i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++ )
        {
            @team = @G_GetTeam( i );
            team.stats.clear();

            // respawn all clients inside the playing teams
            for ( int j = 0; @team.ent( j ) != null; j++ )
            {
                @ent = @team.ent( j );
                ent.client.stats.clear(); // clear player scores & stats
            }
        }

        // clear bonuses
        for ( i = 0; i < maxClients; i++ )
            brBonusScores[i] = 0;

		this.clearLMSCounts();

        this.numRounds = 0;
        this.newRound();
        
        this.players_oneVS = 0;
    }

    // Check if the defined round limit has been reached
    bool GT_RoundlimitHit( void )
    {
        if ( numRounds > brRoundLimit )
        {
            return true;
        }

    	return false;
    }

    void addPlayerBonus( Client @client, int bonus )
    {
        if ( @client == null )
            return;

        brBonusScores[ client.playerNum ] += bonus;
    }

    int getPlayerBonusScore( Client @client )
    {
        if ( @client == null )
            return 0;

        return brBonusScores[ client.playerNum ];
    }

	void clearLMSCounts()
	{
        for ( int i = 0; i < maxClients; i++ )
            brLMSCounts[i] = 0;
	}

    void endGame()
    {
        this.newRoundState( BR_ROUNDSTATE_NONE );

        GENERIC_SetUpEndMatch();
    }

    void newRound()
    {
        G_RemoveDeadBodies();
        G_RemoveAllProjectiles();

        this.newRoundState( BR_ROUNDSTATE_PREROUND );
        this.numRounds++;
    }

    void newRoundState( int newState )
    {
        if ( newState > BR_ROUNDSTATE_POSTROUND )
        {
            this.newRound();
            return;
        }

        this.state = newState;
        this.roundStateStartTime = levelTime;

        switch ( this.state )
        {
        case BR_ROUNDSTATE_NONE:
            this.roundStateEndTime = 0;
            this.countDown = 0;
			this.timelimit = 0;
			this.minuteLeft = 0;
            break;

        case BR_ROUNDSTATE_PREROUND:
        {
            this.roundStateEndTime = levelTime + 7000;
            this.countDown = 5;
			this.timelimit = 0;
			this.minuteLeft = 0;

            // respawn everyone and disable shooting
            gametype.shootingDisabled = true;
            gametype.removeInactivePlayers = false;
	
			this.players_oneVS = 0;

            Entity @ent;
            Team @team;

            for ( int i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++ )
            {
                @team = @G_GetTeam( i );

                // respawn all clients inside the playing teams
                for ( int j = 0; @team.ent( j ) != null; j++ )
                {
                    @ent = @team.ent( j );
                    ent.client.respawn( false );
                }
            }

			this.clearLMSCounts();
	    }
        break;

        case BR_ROUNDSTATE_ROUND:
        {
            gametype.shootingDisabled = false;
            gametype.removeInactivePlayers = true;
            this.countDown = 0;
            this.roundStateEndTime = 0;
            int soundIndex = G_SoundIndex( "sounds/announcer/countdown/fight0" + (1 + (rand() & 1)) );
            G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
            G_CenterPrintMsg( null, 'Fight!');
        }
        break;

        case BR_ROUNDSTATE_ROUNDFINISHED:
            gametype.shootingDisabled = true;
            this.roundStateEndTime = levelTime + 1500;
            this.countDown = 0;
			this.timelimit = 0;
			this.minuteLeft = 0;
            break;

        case BR_ROUNDSTATE_POSTROUND:
        {
            this.roundStateEndTime = levelTime + 3000;

            // add score to round-winning team
            Entity @ent;
            Entity @lastManStanding = null;
            Team @team;
            int count_players;
            int count_players_total;

            count_players = count_players_total = 0;
            @team = @G_GetTeam( TEAM_PLAYERS );
            for ( int j = 0; @team.ent( j ) != null; j++ )
            {
                @ent = @team.ent( j );
                if ( !ent.isGhosting() )
                {
                    count_players++;
                    @lastManStanding = @ent;
                    // ch : add round
                    if( @ent.client != null )
                    	ent.client.stats.addRound();
                }
                count_players_total++;
            }

            int soundIndex;

            if ( count_players == 1 )
            {
                if ( !gametype.isInstagib && count_players == 1 ) // he's the last man standing. Drop a bonus
                {
                    if ( count_players_total > 1 )
                    {
                        lastManStanding.client.addAward( S_COLOR_GREEN + "Last Player Standing!" );
                        // ch :
                        if( players_oneVS > ONEVS_AWARD_COUNT )
                        	// lastManStanding.client.addMetaAward( "Last Man Standing" );
                        	lastManStanding.client.addAward( "Last Man Standing" );

                        this.addPlayerBonus( lastManStanding.client, brLMSCounts[lastManStanding.playerNum] * g_br_lmsbonus.integer );
                        GT_updateScore( lastManStanding.client );
                    }
                }
            }
			else // draw round
            {
                G_CenterPrintMsg( null, "Draw Round!" );
            }
        }
        break;

        default:
            break;
        }
    }

    void think()
    {
        if ( this.state == BR_ROUNDSTATE_NONE )
            return;
		
        if ( match.getState() != MATCH_STATE_PLAYTIME )
        {
            this.endGame();
            return;
        }

        if ( GT_RoundlimitHit() )
        {
            match.launchState( match.getState() + 1 );
            return;
        }

        if ( this.roundStateEndTime != 0 )
        {
            if ( this.roundStateEndTime < levelTime )
            {
                this.newRoundState( this.state + 1 );
                return;
            }

            if ( this.countDown > 0 )
            {
                // we can't use the authomatic countdown announces because their are based on the
                // matchstate timelimit, and prerounds don't use it. So, fire the announces "by hand".
                int remainingSeconds = int( ( this.roundStateEndTime - levelTime ) * 0.001f ) + 1;
                if ( remainingSeconds < 0 )
                    remainingSeconds = 0;

                if ( remainingSeconds < this.countDown )
                {
                    this.countDown = remainingSeconds;

                    if ( this.countDown == 4 )
                    {
                        int soundIndex = G_SoundIndex( "sounds/announcer/countdown/ready0" + (1 + (rand() & 1)) );
                        G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                    }
                    else if ( this.countDown <= 3 )
                    {
                        int soundIndex = G_SoundIndex( "sounds/announcer/countdown/" + this.countDown + "_0" + (1 + (rand() & 1)) );
                        G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );

                    }
                    G_CenterPrintMsg( null, String( this.countDown ) );
                }
            }
        }

        // if one of the teams has no player alive move from BR_ROUNDSTATE_ROUND
        if ( this.state == BR_ROUNDSTATE_ROUND )
        {
			// 1 minute left if 1v1
			if( this.minuteLeft > 0 )
			{
				uint left = this.minuteLeft - levelTime;

				if ( brTimelimit1v1 != 0 && ( brTimelimit1v1 * 1000 ) == left )
				{
					if( brTimelimit1v1 < 60 )
					{
						G_CenterPrintMsg( null, brTimelimit1v1 + " seconds left. Hurry up!" );
					}
					else
					{
						uint minutes;					
						uint seconds = brTimelimit1v1 % 60;
						
						if( seconds == 0 )
						{
							minutes = brTimelimit1v1 / 60;
							if(minutes == 1) {
								G_CenterPrintMsg( null, minutes + " minute left. Hurry up!");
							} else {
								G_CenterPrintMsg( null, minutes + " minutes left. Hurry up!" );							
							}
						}
						else
						{
							minutes = ( brTimelimit1v1 - seconds ) / 60;
							G_CenterPrintMsg( null, minutes + " minutes and "+ seconds +" seconds left. Hurry up!"  );
						}
					}
				}
				
                int remainingSeconds = int( left * 0.001f ) + 1;
                if ( remainingSeconds < 0 )
                    remainingSeconds = 0;
				
				this.timelimit = remainingSeconds;
				match.setClockOverride( minuteLeft - levelTime );
				
				if( levelTime > this.minuteLeft )
				{
					G_CenterPrintMsg( null , S_COLOR_RED + 'Timelimit hit!');
					this.newRoundState( this.state + 1 );
				}
			}
		
			// if there's only one player alive move from BR_ROUNDSTATE_ROUND
            Entity @ent;
            Team @team;
            int count;

            @team = @G_GetTeam( TEAM_PLAYERS );
            count = 0;

            for ( int j = 0; @team.ent( j ) != null; j++ )
            {
                @ent = @team.ent( j );
                if ( !ent.isGhosting() )
                    count++;
            }

            if ( count == 1 )
            {
                this.newRoundState( this.state + 1 );
            }
        }
    }

    void playerKilled( Entity @target, Entity @attacker, Entity @inflictor )
    {
        Entity @ent;
        Team @team;

        if ( this.state != BR_ROUNDSTATE_ROUND )
            return;

        if ( @target != null && @target.client != null && @attacker != null && @attacker.client != null )
        {
			G_PrintMsg( target, "You were fragged by " + attacker.client.name + "\n" );

            // if the attacker is the only remaining player on the team,
            // report number or remaining enemies

            int playersCount = -1;

            // count players
            @team = @G_GetTeam( TEAM_PLAYERS );
            for ( int j = 0; @team.ent( j ) != null; j++ )
            {
                @ent = @team.ent( j );
                if ( !ent.isGhosting() )
                    playersCount++;
            }

            // Increment a player's LMS score each time they get a kill
            brLMSCounts[attacker.playerNum]++;

            if ( playersCount == 2 )
            {
                G_PrintMsg( null, "1v1! Good luck!\n" );
                attacker.client.addAward( "1v1! Good luck!" );

                // find the other alive player
                @team = @G_GetTeam( TEAM_PLAYERS );
                for ( int j = 0; @team.ent( j ) != null; j++ )
                {
                    @ent = @team.ent( j );
                    if ( ent.isGhosting() || @ent == @target || @ent == @attacker )
                        continue;

                    ent.client.addAward( S_COLOR_ORANGE + "1v1! Good luck!" );
                    break;
                }
				
				this.minuteLeft = levelTime + ( brTimelimit1v1 * 1000 );
            }
            
			award_playerKilled( @target, @attacker, @inflictor );
        }
        
        // ch : add a round for victim
        if ( @target != null && @target.client != null )
        	target.client.stats.addRound();
    }
}

cBRRound brRound;

///*****************************************************************
/// NEW MAP ENTITY DEFINITIONS
///*****************************************************************


///*****************************************************************
/// LOCAL FUNCTIONS
///*****************************************************************

void BR_SetUpWarmup()
{
    GENERIC_SetUpWarmup();

    // set spawnsystem type to instant while players join
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );
}

void BR_SetUpCountdown()
{
    gametype.shootingDisabled = true;
    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    G_RemoveAllProjectiles();

    // Countdowns should be made entirely client side, because we now can

    int soundIndex = G_SoundIndex( "sounds/announcer/countdown/get_ready_to_fight0" + (1 + (rand() & 1)) );
    G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
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

        response += "\n";
        response += "Gametype " + gametype.name + " : " + gametype.title + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.version + "\n";
        response += "Author: " + gametype.author + "\n";
        response += "Mod: " + fs_game.string + (!manifest.empty() ? " (manifest: " + manifest + ")" : "") + "\n";
        response += "----------------\n";

        G_PrintMsg( client.getEnt(), response );
        return true;
    }
    else if ( cmdString == "cvarinfo" )
    {
        GENERIC_CheatVarResponse( client, cmdString, argsString, argc );
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
    Entity @goal;
    Bot @bot;

    @bot = @ent.client.getBot();
    if ( @bot == null )
        return false;

    float offensiveStatus = GENERIC_OffensiveStatus( ent );

    // loop all the goal entities
    for ( int i = AI::GetNextGoal( AI::GetRootGoal() ); i != AI::GetRootGoal(); i = AI::GetNextGoal( i ) )
    {
        @goal = @AI::GetGoalEntity( i );

        // by now, always full-ignore not solid entities
        if ( goal.solid == SOLID_NOT )
        {
            bot.setGoalWeight( i, 0 );
            continue;
        }

        if ( @goal.client != null )
        {
            bot.setGoalWeight( i, GENERIC_PlayerWeight( ent, goal ) * 2.5 * offensiveStatus );
            continue;
        }

        // ignore it
        bot.setGoalWeight( i, 0 );
    }

    return true; // handled by the script
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

        int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;

        // "Name Clan Score Frags Ping R"
        entry = "&p " + playerID + " " + ent.client.clanName + " "
                + ent.client.stats.score + " " + ent.client.stats.frags + " "
                + ent.client.ping + " " + ( ent.client.isReady() ? "1" : "0" ) + " ";

        if ( scoreboardMessage.len() + entry.len() < maxlen )
            scoreboardMessage += entry;
    }

    return scoreboardMessage;
}

//
void GT_updateScore( Client @client )
{
    if ( @client != null )
    {
        client.stats.setScore( client.stats.frags + brRound.getPlayerBonusScore( client ) );
    }
}

// Some game actions trigger score events. These are events not related to killing
// oponents, like capturing a flag
// Warning: client can be null
void GT_ScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( score_event == "kill" )
    {
        Entity @attacker = null;

        if ( @client != null )
            @attacker = @client.getEnt();

        int arg1 = args.getToken( 0 ).toInt();
        int arg2 = args.getToken( 1 ).toInt();

        // target, attacker, inflictor
        brRound.playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );

		if ( match.getState() == MATCH_STATE_PLAYTIME )
		{
			GT_updateScore( client );
		}
    }
	else if( score_event == "rebalance" || score_event == "shuffle" )
	{
		// end round when in match
		if ( ( @client == null ) && ( match.getState() == MATCH_STATE_PLAYTIME ) )
		{
			brRound.newRoundState( BR_ROUNDSTATE_ROUNDFINISHED );
		}	
	}
}

// a player is being respawned. This can happen from several ways, as dying, changing team,
// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
void GT_PlayerRespawn( Entity @ent, int old_team, int new_team )
{
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
    	// give the weapons and ammo as defined in cvars
    	String token, weakammotoken, ammotoken;
    	String itemList = g_noclass_inventory.string;
    	String ammoCounts = g_class_strong_ammo.string;

    	ent.client.inventoryClear();

        for ( int i = 0; ;i++ )
        {
            token = itemList.getToken( i );
            if ( token.len() == 0 )
                break; // done

            Item @item = @G_GetItemByName( token );
            if ( @item == null )
                continue;

            ent.client.inventoryGiveItem( item.tag );

            // if it's ammo, set the ammo count as defined in the cvar
            if ( ( item.type & IT_AMMO ) != 0 )
            {
                token = ammoCounts.getToken( item.tag - AMMO_GUNBLADE );

                if ( token.len() > 0 )
                {
                    ent.client.inventorySetCount( item.tag, token.toInt() );
                }
            }
        }

        // give armor
        ent.client.armor = 150;

        // select rocket launcher
        ent.client.selectWeapon( WEAP_ROCKETLAUNCHER );
    }

    // auto-select best weapon in the inventory
    if( ent.client.pendingWeapon == WEAP_NONE )
		ent.client.selectWeapon( -1 );

    // add a teleportation effect
    ent.respawnEffect();
}

// Thinking function. Called each frame
void GT_ThinkRules()
{
    if ( match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished() )
        match.launchState( match.getState() + 1 );

	GENERIC_Think();

    // print count of players alive and show class icon in the HUD

    Team @team;
    int[] alive( GS_MAX_TEAMS );

    alive[TEAM_SPECTATOR] = 0;
    alive[TEAM_PLAYERS] = 0;

    for ( int t = TEAM_PLAYERS; t < GS_MAX_TEAMS; t++ )
    {
        @team = @G_GetTeam( t );
        for ( int i = 0; @team.ent( i ) != null; i++ )
        {
            if ( !team.ent( i ).isGhosting() )
                alive[t]++;
        }
    }

    G_ConfigString( CS_GENERAL, "" + alive[TEAM_PLAYERS] );
    G_ConfigString( CS_GENERAL + 1, "" + alive[TEAM_PLAYERS] );

    for ( int i = 0; i < maxClients; i++ )
    {
        Client @client = @G_GetClient( i );

        if ( match.getState() >= MATCH_STATE_POSTMATCH || match.getState() < MATCH_STATE_PLAYTIME )
        {
            client.setHUDStat( STAT_MESSAGE_ALPHA, 0 );
            client.setHUDStat( STAT_MESSAGE_BETA, 0 );
            client.setHUDStat( STAT_IMAGE_BETA, 0 );
        }
        else
        {
            client.setHUDStat( STAT_MESSAGE_ALPHA, CS_GENERAL );
            client.setHUDStat( STAT_MESSAGE_BETA, CS_GENERAL + 1 );
        }

        if ( client.getEnt().isGhosting()
                || match.getState() >= MATCH_STATE_POSTMATCH )
        {
            client.setHUDStat( STAT_IMAGE_BETA, 0 );
        }
    }

    if ( match.getState() >= MATCH_STATE_POSTMATCH )
        return;

    brRound.think();
}

// The game has detected the end of the match state, but it
// doesn't advance it before calling this function.
// This function must give permission to move into the next
// state by returning true.
bool GT_MatchStateFinished( int incomingMatchState )
{
    // ** MISSING EXTEND PLAYTIME CHECK **

    if ( match.getState() <= MATCH_STATE_WARMUP && incomingMatchState > MATCH_STATE_WARMUP
            && incomingMatchState < MATCH_STATE_POSTMATCH )
        match.startAutorecord();

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
        BR_SetUpWarmup();
        break;

    case MATCH_STATE_COUNTDOWN:
        BR_SetUpCountdown();
        break;

    case MATCH_STATE_PLAYTIME:
        brRound.newGame();
        break;

    case MATCH_STATE_POSTMATCH:
        brRound.endGame();
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
    gametype.title = "Warfork Royale";
    gametype.version = "0.0.1";
    gametype.author = "Warsow Development Team";
    // Forked by Gelmo

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
                 + "// This config will be executed each time the gametype is started\n"
                 + "\n\n// map rotation\n"
                 + "set g_maplist \"wfca1\" // list of maps in automatic rotation\n"
                 + "set g_maprotation \"0\"   // 0 = same map, 1 = in order, 2 = random\n"
                 + "\n// game settings\n"
                 + "set g_scorelimit \"0\"\n"
                 + "set g_timelimit \"0\"\n"
                 + "set g_warmup_timelimit \"1\"\n"
                 + "set g_match_extendedtime \"0\"\n"
                 + "set g_allow_falldamage \"0\"\n"
                 + "set g_allow_selfdamage \"0\"\n"
                 + "set g_allow_teamdamage \"0\"\n"
                 + "set g_allow_stun \"0\"\n"
                 + "set g_teams_maxplayers \"8\"\n"
                 + "set g_teams_allow_uneven \"0\"\n"
                 + "set g_countdown_time \"3\"\n"
                 + "set g_maxtimeouts \"1\" // -1 = unlimited\n"
                 + "\n// gametype settings\n"
				 + "set g_br_timelimit1v1 \"60\"\n"
                 + "set g_br_lmsbonus \"1\"\n"
                 + "set g_br_roundlimit \"10\"\n"
                 + "\n// classes settings\n"
                 + "set g_noclass_inventory \"gb mg rg gl rl pg lg eb cells shells grens rockets plasma lasers bolts bullets\"\n"
                 + "set g_class_strong_ammo \"1 75 20 20 40 125 180 15\" // GB MG RG GL RL PG LG EB\n"
                 + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

	brTimelimit1v1 = g_br_timelimit1v1.integer;
    brRoundLimit = g_br_roundlimit.integer;

    gametype.spawnableItemsMask = 0;
    gametype.respawnableItemsMask = 0;
    gametype.dropableItemsMask = 0;
    gametype.pickableItemsMask = 0;

    gametype.isTeamBased = false;
    gametype.isRace = false;
    gametype.hasChallengersQueue = false;
    gametype.maxPlayersPerTeam = 0;

    gametype.ammoRespawn = 20;
    gametype.armorRespawn = 25;
    gametype.weaponRespawn = 15;
    gametype.healthRespawn = 25;
    gametype.powerupRespawn = 90;
    gametype.megahealthRespawn = 20;
    gametype.ultrahealthRespawn = 60;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = false;
    gametype.shootingDisabled = false;
    gametype.infiniteAmmo = false;
    gametype.canForceModels = true;
    gametype.canShowMinimap = false;
    gametype.teamOnlyMinimap = true;
    gametype.removeInactivePlayers = true;

	gametype.mmCompatible = true;
	
    gametype.spawnpointRadius = 256;

    if ( gametype.isInstagib )
        gametype.spawnpointRadius *= 2;

    // set spawnsystem type to instant while players join
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );

    // define the scoreboard layout
    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %l 48 %r l1" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Frags Ping R" );

    // add commands
    G_RegisterCommand( "gametype" );

    G_Print( "Gametype '" + gametype.title + "' initialized\n" );
}