/*
Copyright (C) 2014 Matthew Sanders

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

 ** hoonymode.as by iim a.k.a. iimosaurus (Matthew Sanders)
 **     Need help? Find me at #warsow.au @QuakeNet
 ** Date: 25/02/2014
 **
 ** Notes: Original hoonymode requires a 2-point lead, but with Warsow 
 **        being less lethal, I'm choosing to forgo that and just make it first to 3
 **
 **        If you use this, it'd be awesome if you left credits in, 
 **         and let me know what you use it for! :D
 **
 **                ENJOY! 
 **                       <3 iim
*/
int prcYesIcon;
int prcShockIcon;
int prcShellIcon;

Entity @alphaSpawn;
Entity @betaSpawn;

//The idea for the state logic is basically just pinched from DA.
const int HOONII_ROUNDSTATE_NONE = 0;
const int HOONII_ROUNDSTATE_PREPICK = 1;
const int HOONII_ROUNDSTATE_PICK = 2;
const int HOONII_ROUNDSTATE_PREROUND = 3;
const int HOONII_ROUNDSTATE_RESPAWNROUND = 4;
const int HOONII_ROUNDSTATE_ROUND = 5;
const int HOONII_ROUNDSTATE_ROUNDFINISHED = 6;
const int HOONII_ROUNDSTATE_PRESWAP = 7;
const int HOONII_ROUNDSTATE_SWAP = 8;
const int HOONII_ROUNDSTATE_PREROUND2 = 9;
const int HOONII_ROUNDSTATE_RESPAWNROUND2 = 10;
const int HOONII_ROUNDSTATE_ROUND2 = 11;
const int HOONII_ROUNDSTATE_ROUNDFINISHED2 = 12;
const int HOONII_ROUNDSTATE_WINCHECK = 13;
const int HOONII_ROUNDSTATE_GAMEFINISHED = 14;

bool alphaReady = false;
bool betaReady = false;

bool alphaPicked;
bool betaPicked;
bool startRespawn = false;

class cHoonyRound
{
    int state;
    int numRounds;
    int advantage;
    bool winnerfound;
    uint roundStateStartTime;
    uint roundStateEndTime;
    int countDown;
    Entity @alphaSpawn;
    Entity @betaSpawn;

    cHoonyRound()
    {
        this.state = HOONII_ROUNDSTATE_NONE;
        this.numRounds = 0;
        this.roundStateStartTime = 0;
        this.countDown = 0;
        @this.alphaSpawn = null;
        @this.betaSpawn = null;
    }
    ~cHoonyRound() {}


//STEPS
// 0. Both player confirm to play Hoonymode (using generic duel ready atm?)
// 1. Both players pick spawns
// 2. Both players ready
// 3. Phase 1 fight
// 4. Swap spawns (re-ready)
// 5. Phase 2 fight
// 6. If score = win, goto Step 7, else goto Step 1
// 7. PLAYER X WINAR
    
    void init()
    {
        
    }

    void newGame()
    {
        gametype.readyAnnouncementEnabled = false;
        gametype.scoreAnnouncementEnabled = true;
        gametype.countdownEnabled = false;

        //INSTANT SPAWN WHILE PICKING
        for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
            gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, true );

        Entity @ent;
        Team @team;

        for ( int i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++ )
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

        winnerfound = false;
          
        this.numRounds = 0;
        this.newRound();

    }

    void endGame()
    {
        this.newRoundState( HOONII_ROUNDSTATE_NONE );
        GENERIC_SetUpEndMatch();
    }

    void newRound()
    {
        G_RemoveDeadBodies();
        G_RemoveAllProjectiles();

        this.numRounds++;
        this.newRoundState( 1 );
    }

    void newRoundState( int newState )
    {
        if ( newState > HOONII_ROUNDSTATE_GAMEFINISHED )
        {
            this.newRound();
            return;
        }

        this.state = newState;
        this.roundStateStartTime = levelTime;

        switch ( this.state )
        {
            case HOONII_ROUNDSTATE_NONE:
                //G_Print("STATE: HOONII_ROUNDSTATE_NONE");
                this.roundStateEndTime = 0;
                this.countDown = 0;
                break;
            case HOONII_ROUNDSTATE_PREPICK:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_PREPICK");
                alphaPicked = false;
                betaPicked = false;
                this.roundStateEndTime = levelTime + 2500;

                gametype.shootingDisabled = true;
                gametype.pickableItemsMask = 0;
                G_Items_RespawnByType( 0, 0, 0 );

                //Can't figure out how to unlink/destroy the spawn entities...
                //But I should totally do that here if possible.
                //As it is, it's not a big deal if they carry over

                /*
                if(@this.alphaSpawn != null && @this.betaSpawn != null)
                {
                    this.alphaSpawn.freeEntity();
                    this.betaSpawn.freeEntity();
                    @this.alphaSpawn = null;
                    @this.betaSpawn = null;
                }
                */

                respawnPlayers(false);

                String alphaname = G_GetTeam(TEAM_ALPHA).ent(0).client.name;
                String betaname  = G_GetTeam(TEAM_BETA ).ent(0).client.name;
 
                if(numRounds == 1)
                {
                    G_CenterPrintMsg(null, S_COLOR_GREEN + 'Round '+numRounds+'\n'
                                   + S_COLOR_WHITE + alphaname
                                   + S_COLOR_GREEN + " vs. "
                                   + S_COLOR_WHITE + betaname );
                }
                if(numRounds > 1)
                {
                    G_CenterPrintMsg( null, S_COLOR_GREEN + 'Round '+numRounds+'\n');
                }
                break;
            }
            
            case HOONII_ROUNDSTATE_PICK:
            {
                SpawnIndicators::Create("info_player_deathmatch", TEAM_PLAYERS);
                //G_Print("STATE: HOONII_ROUNDSTATE_PICK\n");
                G_CenterPrintMsg( null, S_COLOR_WHITE+'Pick spawn positions with the menu or'
                                       +S_COLOR_ORANGE+' /pick\n'
                                       +S_COLOR_WHITE+'Then use the menu or' 
                                       +S_COLOR_ORANGE+' /roundready'
                                       +S_COLOR_WHITE+' to begin!\n');
                gametype.shootingDisabled = false;
                gametype.pickableItemsMask = 0;
                gametype.countdownEnabled = false;

                break;
            }

            case HOONII_ROUNDSTATE_PREROUND:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_PREROUND\n");
                this.roundStateEndTime = levelTime + 5000;
                this.countDown = 5;
                gametype.shootingDisabled = true;
                SpawnIndicators::Delete();
                break;
            }

            // I'm tempted to use normal duel item timers for initial spawns
            /*
                G_Items_RespawnByType( IT_ARMOR, 0, 15 );
                G_Items_RespawnByType( IT_HEALTH, HEALTH_MEGA, 15 );
                G_Items_RespawnByType( IT_HEALTH, HEALTH_ULTRA, 15 );
                G_Items_RespawnByType( IT_POWERUP, 0, brandom( 20, 40 ) );
            */
            // Instant spawning speeds up the rounds a bit

            case HOONII_ROUNDSTATE_RESPAWNROUND:
            {
                respawnPlayers(false);
                this.roundStateEndTime = levelTime + 50;
                this.countDown = 0;
                break;
            }

            case HOONII_ROUNDSTATE_ROUND:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_ROUND\n");    
                gametype.pickableItemsMask = gametype.spawnableItemsMask;
                gametype.shootingDisabled = false;
                this.roundStateEndTime = 0;
                this.countDown = 0;

                //respawnPlayers();

                int soundIndex = G_SoundIndex( "sounds/announcer/countdown/fight0" + int( brandom( 1, 2 ) ) );
                G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                G_CenterPrintMsg( null, 'Fight!\n');
                break;
            }

            case HOONII_ROUNDSTATE_ROUNDFINISHED:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_ROUNDFINISHED\n");
                //Show a pretty announcement about who's in the lead
                this.roundStateEndTime = levelTime + 2500;
                this.countDown = 0;
                break;
            }

            case HOONII_ROUNDSTATE_PRESWAP:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_PRESWAP\n");
                (advantage==TEAM_ALPHA)
                    ?G_CenterPrintMsg(null, "ADVANTAGE : "+G_GetTeam(TEAM_ALPHA).ent(0).client.name+"\n")
                    :G_CenterPrintMsg(null, "ADVANTAGE : "+G_GetTeam(TEAM_BETA ).ent(0).client.name+"\n");
                this.roundStateEndTime = levelTime + 2500;
                gametype.shootingDisabled = true;
                break;
            }

            case HOONII_ROUNDSTATE_SWAP:
            {
                //This is essentially a second "pick" 
                //just without picking...

                //G_Print("STATE: HOONII_ROUNDSTATE_SWAP\n");

                /*
                G_CenterPrintMsg( null, S_COLOR_WHITE+'Use the menu or'
                                       +S_COLOR_ORANGE+' /roundready'
                                       +S_COLOR_WHITE+' to ready up for the next round');
                */
                G_CenterPrintMsg( null, S_COLOR_WHITE+'Ready up to start the next round!' );
                gametype.shootingDisabled = false;
                gametype.pickableItemsMask = 0;
                gametype.countdownEnabled = false;

                swapPlayerSpawns();
                respawnPlayers(false);
                G_Items_RespawnByType( 0, 0, 0 );

                break;
            }

            case HOONII_ROUNDSTATE_PREROUND2:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_PREROUND2\n");
                this.roundStateEndTime = levelTime + 5000;
                this.countDown = 5;
                gametype.shootingDisabled = true;
                //for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
                    //gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_HOLD, 0, 0, true );
                //SpawnIndicators::Delete();
                break;
            }
            case HOONII_ROUNDSTATE_RESPAWNROUND2:
            {
                respawnPlayers(false);
                this.roundStateEndTime = levelTime + 50;
                this.countDown = 0;
                break;
            }
            case HOONII_ROUNDSTATE_ROUND2:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_ROUND2\n");    
                gametype.pickableItemsMask = gametype.spawnableItemsMask;
                gametype.shootingDisabled = false;
                G_Items_RespawnByType( 0, 0, 0 );
                this.roundStateEndTime = 0;
                this.countDown = 0;

                int soundIndex = G_SoundIndex( "sounds/announcer/countdown/fight0" + int( brandom( 1, 2 ) ) );
                G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                G_CenterPrintMsg( null, 'Fight!\n');
                break;
            }

            case HOONII_ROUNDSTATE_ROUNDFINISHED2:
            {
                //G_Print("STATE: HOONII_ROUNDSTATE_ROUNDFINISHED2\n");
                Entity @ent;
                int i=0;
                Cvar scoreLimit( "g_scorelimit", "", 0 );
                this.roundStateEndTime = levelTime + 2500;
                this.countDown = 0;
                while(i<maxClients)
                {
                    @ent = @G_GetClient( i ).getEnt();
                    if(ent.client.stats.score >= scoreLimit.integer)
                        winnerfound = true;
                    if(winnerfound)
                        break;
                    i++;
                }
                
                break;
            }
            case HOONII_ROUNDSTATE_WINCHECK:
            {
                if(winnerfound)
                {
                    // For a win message, maybe we can just make this a delay by 
                    // giving it roundStateEndTime and letting it auto advance
                    this.newRoundState(HOONII_ROUNDSTATE_GAMEFINISHED);
                }
                else
                {
                    this.newRound();
                }
                break;
            }
        }
    }
    void think()
    {
        //This is dumb, it stops from "telefragging" on spawn
        // #latenightsolutions
        if (startRespawn)
        {
            respawnPlayers(true);
            startRespawn = false;
        }

        if ( this.state == HOONII_ROUNDSTATE_NONE )
            return;

        if ( this.state == HOONII_ROUNDSTATE_PICK || this.state == HOONII_ROUNDSTATE_SWAP)
        {
            //Basically invuln, though can still telefrag.
            //Do it this way so we can still GB jump around and 
            //get to all the important spawns reasonably quick
            Entity @ent;
            for ( int i = 0; i < maxClients; i++ )
            {
                @ent = @G_GetClient( i ).getEnt();
                if(ent.health<100)
                    ent.health = 100;
            }

            if(alphaReady && betaReady)
            {
                alphaReady = false;
                betaReady = false;
                this.newRoundState(this.state + 1);
            }
            if(alphaReady && G_GetTeam(TEAM_BETA).ent(0).client.isBot() || betaReady && G_GetTeam(TEAM_ALPHA).ent(0).client.isBot())
            {
                alphaReady = false;
                betaReady = false;
                this.newRoundState(this.state + 1);
            }
        }

        // This is used a whole bunch, mostly just to show 
        // messages on screen with G_CenterPrintMsg 
        // (there's probably a way easier way of doing that)

        if(this.state == HOONII_ROUNDSTATE_PREPICK
            || this.state == HOONII_ROUNDSTATE_PREROUND 
            || this.state == HOONII_ROUNDSTATE_RESPAWNROUND
            || this.state == HOONII_ROUNDSTATE_ROUNDFINISHED 
            || this.state == HOONII_ROUNDSTATE_PRESWAP
            || this.state == HOONII_ROUNDSTATE_PREROUND2
            || this.state == HOONII_ROUNDSTATE_RESPAWNROUND2 
            || this.state == HOONII_ROUNDSTATE_ROUNDFINISHED2)
        {
            Entity @ent;
            for ( int i = 0; i < maxClients; i++ )
            {
                @ent = @G_GetClient( i ).getEnt();
                if(ent.health<100)
                    ent.health = 100;
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
                    // we can't use the automatic countdown announces because their are based on the
                    // matchstate timelimit, and prerounds don't use it. So, fire the announces "by hand".
                    int remainingSeconds = int( ( this.roundStateEndTime - levelTime ) * 0.001f ) + 1;
                    if ( remainingSeconds < 0 )
                        remainingSeconds = 0;

                    if ( remainingSeconds < this.countDown )
                    {
                        this.countDown = remainingSeconds;

                        if ( this.countDown == 4 )
                        {
                            int soundIndex = G_SoundIndex( "sounds/announcer/countdown/ready0" + int( brandom( 1, 2 ) ) );
                            G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                        }
                        else if ( this.countDown <= 3 )
                        {
                            int soundIndex = G_SoundIndex( "sounds/announcer/countdown/" + this.countDown + "_0" + int( brandom( 1, 2 ) ) );
                            G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                        }
                        G_CenterPrintMsg( null , this.countDown + '\n');
                    }
                }
            }
        }

        //We use this to handle deaths, handling roundstate in playerKilled seemed messy
        if (this.state == HOONII_ROUNDSTATE_ROUND || this.state == HOONII_ROUNDSTATE_ROUND2)
        {
            int count = 0;

            Entity @ent;
            for ( int i = 0; i < maxClients; i++ )
            {
                @ent = @G_GetClient( i ).getEnt();
                if(!ent.isGhosting())
                    count++;
            }
            if ( count < 2 )
                this.newRoundState( this.state + 1 );
        }
    }

    void playerKilled(Entity @target, Entity @attacker, Entity @inflicter)
    {
        if(this.state != HOONII_ROUNDSTATE_ROUND && this.state != HOONII_ROUNDSTATE_ROUND2)
            return;

        //Shouldn't ever occur?
        if ( @target == null || @target.client == null )
            return;

        //If it's suicide (ie. null attacker), it's still properly handled below
        //if ( @attacker == null || @attacker.client == null )

        //round 1 can go either way
        if(this.state == HOONII_ROUNDSTATE_ROUND)
        {
            //G_Print(attacker.client.name+" FRAGGED "+target.client.name+" WITH "+inflicter.get_classname()+" YO!\n");
            (target.team==TEAM_ALPHA)?advantage=TEAM_BETA:advantage=TEAM_ALPHA;
            this.newRoundState( HOONII_ROUNDSTATE_ROUNDFINISHED );
        }

        //round 2 can draw or win
        //I'm not sure if I should do all this in playerkilled or make a new post-round to check
        if(this.state == HOONII_ROUNDSTATE_ROUND2)
        {
            Entity @winner = null;
            Entity @loser = null;
            int soundIndex;
            
            @loser = target;
            //target.team==TEAM_ALPHA?@winner=G_GetTeam(TEAM_BETA).ent(0):@winner=G_GetTeam(TEAM_ALPHA).ent(0);
            if(target.team == TEAM_ALPHA)
                @winner=G_GetTeam(TEAM_BETA).ent(0);
            else
                @winner=G_GetTeam(TEAM_ALPHA).ent(0);
            
            if(advantage == loser.team) //draw
            {
                //only want recovery 2 or 4, 1/3 reference actual flags
                soundIndex = G_SoundIndex( "sounds/announcer/ctf/recovery0" + 2*int( brandom( 1, 2 ) ) );
                G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                G_CenterPrintMsg( null, 'DRAW!\n');
            }
            else //attacker wins
            {
                //G_Print(""+winner.client.name+" WINS THE ROUND!");
                winner.client.stats.addScore( 1 );
                Team @winteam = G_GetTeam(winner.team);
                winteam.stats.addScore( 1 );

                soundIndex = G_SoundIndex( "sounds/announcer/ctf/score0" + int( brandom( 1, 2 ) ) );
                G_AnnouncerSound( winner.client, soundIndex, GS_MAX_TEAMS, false, null );

                soundIndex = G_SoundIndex( "sounds/announcer/ctf/score_enemy0" + int( brandom( 1, 2 ) ) );
                G_AnnouncerSound( loser.client, soundIndex, GS_MAX_TEAMS, false, null );
            }
            advantage = 0;
        }

        //Still handle the playerkilled awards as normal
        award_playerKilled( @target, @attacker, @inflicter );
    }
}

cHoonyRound hoonyRound;
///*****************************************************************
/// NEW MAP ENTITY DEFINITIONS
///*****************************************************************


///*****************************************************************
/// LOCAL FUNCTIONS
///*****************************************************************

//void HOONII_SetUpWarmup()
//{
//    GENERIC_SetUpWarmup();
//
//    // set spawnsystem type to instant while players join
//    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
//        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );
//
//    gametype.readyAnnouncementEnabled = true;
//}

void CA_SetUpWarmup()
{
    GENERIC_SetUpWarmup();

    // set spawnsystem type to instant while players join
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );
}

///*****************************************************************
/// MODULE SCRIPT CALLS
///*****************************************************************

bool GT_Command( Client @client, const String &in cmdString, const String &in argsString, int argc )
{
    if ( cmdString == "cvarinfo" )
    {
        GENERIC_CheatVarResponse( client, cmdString, argsString, argc );
        return true;
    }
    // example of registered command
    else if ( cmdString == "gametype" )
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

    else if ( cmdString == "pick" )
    {
        if(client.getEnt().isGhosting())
        {
            return true;
        }
        if(hoonyRound.state == HOONII_ROUNDSTATE_SWAP)
        {
            G_PrintMsg(client.getEnt(), "You don't need to pick again!\n");
            return true;
        }

        //Maybe I should give the second closest spawn here? 
        //Though that could be an unwelcome surprise on spawn
        //This seems better.

        if(hoonyRound.state == HOONII_ROUNDSTATE_PICK)
        {
            //Should really generalise this into a function instead of almost duplicating it
            if(client.getEnt().team == TEAM_ALPHA)
            {
                if(@betaSpawn==null)
                {
                    G_PrintMsg(null, G_GetTeam(TEAM_ALPHA).ent(0).client.name+" has picked\n");
                    @alphaSpawn = GetClosestSpawnPoint(client.getEnt());
                    alphaPicked = true;
                    if(G_GetTeam(TEAM_BETA).ent(0).client.isBot())
                    {
                        @betaSpawn = PickTrueRandomSpawnPoint();
                        while(betaSpawn.origin.distance(alphaSpawn.origin)<1)
                            @betaSpawn = PickTrueRandomSpawnPoint();
                    }
                }
                //Using distance seems like a really hacky way of doing it
                else if((GetClosestSpawnPoint(client.getEnt()).origin.distance(betaSpawn.origin)) > 1 || betaPicked == false)
                {
                    G_PrintMsg(null, G_GetTeam(TEAM_ALPHA).ent(0).client.name+" has picked\n");
                    @alphaSpawn = GetClosestSpawnPoint(client.getEnt());
                    alphaPicked = true;
                }
                else
                    G_PrintMsg(client.getEnt(), "Sorry! Spawn belongs to "+G_GetTeam(TEAM_BETA).ent(0).client.name+"!\n");
            }
            if(client.getEnt().team == TEAM_BETA)
            {
                if(@alphaSpawn==null)
                {
                    G_PrintMsg(null, G_GetTeam(TEAM_BETA).ent(0).client.name+" has picked\n");
                    @betaSpawn = GetClosestSpawnPoint(client.getEnt());
                    betaPicked = true;
                    if(G_GetTeam(TEAM_BETA).ent(0).client.isBot())
                    {
                        @alphaSpawn = PickTrueRandomSpawnPoint();
                        while(alphaSpawn.origin.distance(betaSpawn.origin)<1)
                            @alphaSpawn = PickTrueRandomSpawnPoint();
                    }

                }
                else if((GetClosestSpawnPoint(client.getEnt()).origin.distance(alphaSpawn.origin)) > 1 || alphaPicked == false)
                {
                    G_PrintMsg(null, G_GetTeam(TEAM_BETA).ent(0).client.name+" has picked\n");
                    @betaSpawn = GetClosestSpawnPoint(client.getEnt());
                    betaPicked = true;

                }
                else
                    G_PrintMsg(client.getEnt(), "Sorry! Spawn belongs to "+G_GetTeam(TEAM_ALPHA).ent(0).client.name+"!\n");
            }
        }

        if(hoonyRound.state != HOONII_ROUNDSTATE_PICK)
        {
            G_PrintMsg(client.getEnt(), "Not pick time!\n");
            return true;
        }
        
        return true;
    }

    else if ( cmdString == "gametypemenu" )
    {
        if (hoonyRound.state == HOONII_ROUNDSTATE_PICK && !client.getEnt().isGhosting())
        {
            //if we're in pick mode show the pick and ready options
            client.execGameCommand( "mecu \"Game Menu\" \"Pick spawn\" \"pick\" \"Ready\" \"roundready\"  \"Help\" \"helpmenu\" " );
        }
        else if (hoonyRound.state == HOONII_ROUNDSTATE_SWAP && !client.getEnt().isGhosting())
        {
            //if we're in swap mode only show the ready option
            client.execGameCommand( "mecu \"Game Menu\" \"Ready\" \"roundready\"  \"Help\" \"helpmenu\" " );
        }
        else
        {
            //otherwise only show help
            client.execGameCommand( "mecu \"Game Menu\" \"Help\" \"helpmenu\" " );
        }

        return true;
    }

    else if ( cmdString == "helpmenu")
    {
        client.printMessage("\n");
        client.printMessage("^7---HOONYMODE  HELP---\n");
        client.printMessage("^7Pick a spawn using the menu, or bind a key to " +S_COLOR_ORANGE+"/pick\n");
        client.printMessage("^7Ready up with the menu, or bind a key to "+S_COLOR_ORANGE+"/roundready\n");
        client.printMessage("^7After the first fight, players swap spawns and fight again!\n");
        client.printMessage("^7First to the score limit wins!\n");
        client.printMessage("^7---- END OF HELP ----\n");
        client.printMessage("\n");
    }

    else if (cmdString == "roundready")
    {
        if(client.getEnt().isGhosting())
        {
            return true;
        }
        //create team ready system to use between rounds
        if(hoonyRound.state != HOONII_ROUNDSTATE_PICK && hoonyRound.state != HOONII_ROUNDSTATE_SWAP)
        {
            G_PrintMsg(client.getEnt(), "Not pick time!\n");
            return true;
        }

        // If not picked, then it randoms
        //  Also always randoms for bots
        if(client.getEnt().team == TEAM_ALPHA && @alphaSpawn == null || client.getEnt().team == TEAM_ALPHA && !alphaPicked && hoonyRound.state != HOONII_ROUNDSTATE_SWAP)
        {
            //@alphaSpawn = GENERIC_SelectBestRandomSpawnPoint(client.getEnt(),"info_player_deathmatch");
            @alphaSpawn = PickTrueRandomSpawnPoint();
            if(@betaSpawn != null)
            {
                while(alphaSpawn.origin.distance(betaSpawn.origin)<1)
                    @alphaSpawn = PickTrueRandomSpawnPoint();
            }
            alphaPicked = true;
            G_PrintMsg(null, client.name+" has picked a random spawn\n");
            if(G_GetTeam(TEAM_BETA).ent(0).client.isBot())
            {
                @betaSpawn = PickTrueRandomSpawnPoint();
                while(betaSpawn.origin.distance(alphaSpawn.origin)<1)
                    @betaSpawn = PickTrueRandomSpawnPoint();
            }
            toggleReady(client.getEnt().team);
            //G_PrintMsg(client.getEnt(), "Pick spawn with /pick first!");
        }
        else if(client.getEnt().team == TEAM_BETA && @betaSpawn == null || client.getEnt().team == TEAM_BETA && !betaPicked && hoonyRound.state != HOONII_ROUNDSTATE_SWAP)
        {
            @betaSpawn = PickTrueRandomSpawnPoint();
            if(@alphaSpawn != null)
            {
                while(betaSpawn.origin.distance(alphaSpawn.origin)<1)
                    @betaSpawn = PickTrueRandomSpawnPoint();
            }
            betaPicked = true;
            G_PrintMsg(null, client.name+" has picked a random spawn\n");
            if(G_GetTeam(TEAM_ALPHA).ent(0).client.isBot())
            {
                @alphaSpawn = PickTrueRandomSpawnPoint();
                while(alphaSpawn.origin.distance(betaSpawn.origin)<1)
                    @alphaSpawn = PickTrueRandomSpawnPoint();
            }
            toggleReady(client.getEnt().team);
            //G_PrintMsg(client.getEnt(), "Pick spawn with /pick first!");
        }
        else if(client.getEnt().team == TEAM_ALPHA && @alphaSpawn != null)
        {
            toggleReady(client.getEnt().team);
        }
        else if(client.getEnt().team == TEAM_BETA && @betaSpawn != null)
        {
            toggleReady(client.getEnt().team);
        }
        return true;
    }
    return false;
}

void toggleReady(int team)
{
    int soundIndex = G_SoundIndex( "sounds/announcer/pleasereadyup" );
    if(team == TEAM_ALPHA)
    {
        if(!alphaReady)
        {
            G_PrintMsg(null,G_GetTeam(TEAM_ALPHA).ent(0).client.name+" is ready!\n");
            alphaReady=true;
            if(!betaReady)
                G_AnnouncerSound( G_GetTeam(TEAM_BETA).ent(0).client, soundIndex, GS_MAX_TEAMS, false, null );
        }
        else
        {
            G_PrintMsg(null,G_GetTeam(TEAM_ALPHA).ent(0).client.name+" is no longer ready.\n");
            alphaReady=false;
        }
    }
    if(team == TEAM_BETA)
    {
        if(!betaReady)
        {
            G_PrintMsg(null,G_GetTeam(TEAM_BETA).ent(0).client.name+" is ready!\n");
            betaReady=true;
            if(!alphaReady)
                G_AnnouncerSound( G_GetTeam(TEAM_ALPHA).ent(0).client, soundIndex, GS_MAX_TEAMS, false, null );
        }
        else
        {
            G_PrintMsg(null,G_GetTeam(TEAM_BETA).ent(0).client.name+" is no longer ready.\n");
            betaReady=false;  
        }
    }
}

void swapPlayerSpawns()
{
    Entity @temp;
    @temp = @alphaSpawn;
    @alphaSpawn = @betaSpawn;
    @betaSpawn = @temp;
    @temp = null;
    // don't think this does anything, or needs to because it's 
    // only a temporary entity, but I want it destroyed :[
}

// Here we move players for one think frame and then respawn them
// This stops telefragging because players can't respawn at the *exact* same time.

void respawnPlayers(bool respawn)
{
    Entity @ent;
    Team @team;
    for (int i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++ )
    {
        @team = @G_GetTeam( i );
        // respawn all clients inside the playing teams
        //hoonyRound.roundStateEndTime = levelTime + 1;
        for ( int j = 0; @team.ent( j ) != null; j++ )
        {
            @ent = @team.ent( j );
            //ent.client.stats.clear(); // clear player scores & stats
            if(!respawn)
            {
                startRespawn = true;
                ent.set_origin(Vec3(j*100,j*100,j*100));
            }
            else
                ent.client.respawn( false );
        }
    }
}

// Probably shouldn't keep recreating the spawnpoint array every time someone randoms or picks...
// A general pick with a boolean makes sense.
// Better yet creating it once on round start and using for the round with re-creating
// But this does end up more portable/self-contained

// Theoretically the while(alphaSpawn!=betaSpawn){random} could cause a lock 
// but the chances it happens for any significant period are not high.
Entity @PickTrueRandomSpawnPoint()
{
	array<Entity @> @spawnents = G_FindByClassname( "info_player_deathmatch" );
	uint numSpawns = spawnents.size();
    if ( numSpawns == 0 )
        return null;
	return @spawnents[int( brandom( 0, numSpawns - 1 ))];
}

Entity @GetClosestSpawnPoint( Entity @self )
{
	array<Entity @> @spawnents = G_FindByClassname( "info_player_deathmatch" );
	uint numSpawns = spawnents.size();

    if ( numSpawns == 0 )
        return null;
    if ( numSpawns == 1 )
        return @spawnents[0];

    // Get spawn points
    int pos = 0; // Current position
    float closest = 999999;
    int pick = 0;
    float dist = 0;

    //fill array with points
    for( uint i = 0; i < numSpawns; i++ )
    {
		Entity @spawn = @spawnents[i];
        dist = self.origin.distance(spawn.origin);
        if(dist < closest) {
            closest = dist;
            pick = i;
        }
    }
    
    return @spawnents[pick];
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
    //simple bypass of the generic to use the chosen spawns
    if(hoonyRound.state == HOONII_ROUNDSTATE_ROUND 
        || hoonyRound.state == HOONII_ROUNDSTATE_ROUND2 
        || hoonyRound.state == HOONII_ROUNDSTATE_RESPAWNROUND
        || hoonyRound.state == HOONII_ROUNDSTATE_RESPAWNROUND2)
    {
        if(self.team == TEAM_ALPHA && @alphaSpawn != null)
            return alphaSpawn;
        if(self.team == TEAM_BETA && @betaSpawn != null)
            return betaSpawn;
    }
    return GENERIC_SelectBestRandomSpawnPoint( self, "info_player_deathmatch" );
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
            if(hoonyRound.state == HOONII_ROUNDSTATE_PICK || hoonyRound.state == HOONII_ROUNDSTATE_SWAP)
            {
                //We'll make our own readyIcon!
                //With blackjack and hookers!
                if (ent.client.team == TEAM_ALPHA && alphaReady)
                    readyIcon = prcYesIcon;
                else if (ent.client.team == TEAM_BETA && betaReady)
                    readyIcon = prcYesIcon;
                else
                    readyIcon = 0;
            }

            int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;

            // "AVATAR Name Clan Score Frags TKs Ping R"
            entry = "&p " + playerID + " " + playerID + " "
                    + ent.client.clanName + " "
                    + ent.client.stats.score + " "
                    + ent.client.stats.frags + " "
                    + ent.client.stats.suicides + " "
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
// Warning: client can be null
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

        // target, attacker, inflictor
        hoonyRound.playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );
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
        ent.client.inventorySetCount( AMMO_GUNBLADE, 1 ); // enable gunblade blast

        @item = @G_GetItem( WEAP_GUNBLADE );

        @ammoItem = @G_GetItem( item.ammoTag );
        if ( @ammoItem != null )
            ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

        @ammoItem = item.weakAmmoTag == AMMO_NONE ? null : @G_GetItem( item.weakAmmoTag );
        if ( @ammoItem != null )
            ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

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

                @ammoItem = item.weakAmmoTag == AMMO_NONE ? null : @G_GetItem( item.weakAmmoTag );
                if ( @ammoItem != null )
                    ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );
            }

            // give him 2 YAs
            ent.client.inventoryGiveItem( ARMOR_YA );
            ent.client.inventoryGiveItem( ARMOR_YA );
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
void GT_ThinkRules()
{
    if ( match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished() )
    {
        if ( !match.checkExtendPlayTime() )
            match.launchState( match.getState() + 1 );
    }

    GENERIC_Think();

    if ( match.getState() >= MATCH_STATE_POSTMATCH )
        return;

    //float maxArmor = G_GetItem( ARMOR_RA ).quantity;

    // check maxHealth rule and max armor rule
    for ( int i = 0; i < maxClients; i++ )
    {
        Entity @ent = @G_GetClient( i ).getEnt();
        if ( ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR )
        {
            if ( ent.health > ent.maxHealth )
                ent.health -= ( frameTime * 0.001f );

            //if ( ent.client.armor > maxArmor )
            //{
            //    float newArmor = ent.client.armor - ( frameTime * 0.001f );
            //    if ( newArmor < maxArmor )
            //        ent.client.armor = maxArmor;
            //    else
            //        ent.client.armor = newArmor;
            //}

           // GENERIC_ChargeGunblade( ent.client );
        }
    }

    hoonyRound.think();
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
        CA_SetUpWarmup();
        gametype.readyAnnouncementEnabled = true;
        SpawnIndicators::Create("info_player_deathmatch", TEAM_PLAYERS);
        SpawnIndicators::Create("info_player_start", TEAM_PLAYERS);
        break;

    case MATCH_STATE_COUNTDOWN:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        GENERIC_SetUpCountdown();
        SpawnIndicators::Delete();
        break;

    case MATCH_STATE_PLAYTIME:
        hoonyRound.newGame();
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
    gametype.title = "Hoonymode";
    gametype.version = "0.1.3";
    gametype.author = "^6iim^2osaurus";
    // Forked by Gelmo

    hoonyRound.init();

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
                 + "// This config will be executed each time the gametype is started\n"
                 + "\n\n// map rotation\n"
                 + "set g_maplist \"wfda1 wfda2 wfda3 wfda5 wfdm5 wfdm2 wfdm15 cwm2 cwm3 cwl2 cws2 aerorun\" // list of maps in automatic rotation\n"
                 + "set g_maprotation \"2\"   // 0 = same map, 1 = in order, 2 = random\n"
                 + "\n// game settings\n"
                 + "set g_scorelimit \"3\"\n"
                 + "set g_timelimit \"0\"\n"
                 + "set g_warmup_timelimit \"3\"\n"
                 + "set g_match_extendedtime \"2\"\n"
                 + "set g_allow_falldamage \"1\"\n"
                 + "set g_allow_selfdamage \"1\"\n"
                 + "set g_allow_teamdamage \"1\"\n"
                 + "set g_allow_stun \"1\"\n"
                 + "set g_teams_maxplayers \"1\"\n"
                 + "set g_teams_allow_uneven \"0\"\n"
                 + "set g_countdown_time \"5\"\n"
                 + "set g_maxtimeouts \"-1\" // -1 = unlimited\n"
                 + "set g_challengers_queue \"1\"\n"
                 + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

    gametype.spawnableItemsMask = ( IT_WEAPON | IT_AMMO | IT_ARMOR | IT_HEALTH );
    if ( gametype.isInstagib )
        gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);

    gametype.respawnableItemsMask = gametype.spawnableItemsMask ;
    gametype.dropableItemsMask = gametype.spawnableItemsMask;
    gametype.pickableItemsMask = ( gametype.spawnableItemsMask | gametype.dropableItemsMask );

    gametype.isTeamBased = true;
    gametype.isRace = false;
    gametype.hasChallengersQueue = true;
    gametype.maxPlayersPerTeam = 1;

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

    gametype.mmCompatible = true;
    
    gametype.spawnpointRadius = 64;

    if ( gametype.isInstagib )
        gametype.spawnpointRadius *= 2;

    // set spawnsystem type
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );

    // define the scoreboard layout
    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%a l1 %n 112 %s 52 %i 42 %i 40 %i 40 %l 40 %p 18" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "AVATAR Name Clan Sco Fra Sui Ping R" );

    // precache images that can be used by the scoreboard
    prcYesIcon = G_ImageIndex( "gfx/hud/icons/vsay/yes" );
    prcShockIcon = G_ImageIndex( "gfx/hud/icons/powerup/quad" );
    prcShellIcon = G_ImageIndex( "gfx/hud/icons/powerup/warshell" );

    // add commands
    G_RegisterCommand( "pick" );
    G_RegisterCommand( "roundready" );
    G_RegisterCommand( "gametype" );
    G_RegisterCommand( "gametypemenu" );
    G_RegisterCommand( "helpmenu" );

    G_Print( "Gametype '" + gametype.title + "' initialized\n" );
}
