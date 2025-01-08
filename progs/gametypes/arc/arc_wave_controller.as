/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/
int[] CLEAR_ARRAY(); //todo: figure out how to clear a array lol

// define array position where info being accessed is located.
const int MISSION_MAX_ENEMIES = 0;
const int MISSION_WAVE_ENEMIES = 1;
const int MISSION_ENEMY_TYPE = 2;
const int MISSION_ENEMY_NUMBER = 3;

const int WAVE_DELAYED_START = 15000; // amount of time between wave start and spawning enemies

const int CHEST_FREQUENCY = 8; // spawn chest every 8 enemies

class cWaveController
{
    int chestSpawn; // amount of enemies left before chest spawns
    int chestSpawned;
    int enemyCount; // current amount of enemies
    int enemyCountRemaining; // amount of enemies left in Wave_Active
    int enemyCountTotal; // total amount in wave when it started
    int waveCountTotal; // total number of waves
    int waveIndex; // wave you're on
	float waveDamageMod; // modification on damage done by enemies this wave
	float waveHealthMod; // modification on health that enemies this wave have
	float waveSpeedMod; // modification on speed that enemies this wave have
    int state;
    int mapSize;
    uint missionStartTime;
    uint nextThink;
    int[] Mission; // current mission
    int[] Wave_Active;
    Vec3[] Spawn_Locations;

    int countDown;
    uint countDownTime;

    bool portalActivated;
    bool enemyExplode;
	int deathSoundIndex;

    int retries;

    void Init()
    {
        this.enemyCount = 0;
        this.waveCountTotal = 0;
        this.waveIndex = 1; //start on the first wave
        this.retries = 0;
        this.state = MATCH_STATE_WARMUP;
        this.countDownTime = NO_COUNT;
        this.nextThink = levelTime+5000;
        this.chestSpawn = CHEST_FREQUENCY;
        this.chestSpawned = 0;
        this.mapSize = arc_mapsize.get_integer();

		this.waveDamageMod = 1.0f;
		this.waveHealthMod = 1.0f;
		this.waveSpeedMod = 1.0f;

		deathSoundIndex = G_SoundIndex( "sounds/players/male/falldeath.ogg");
        portalActivated = false;
        enemyExplode = false;
    }

    Vec3 ChooseSpawn()
    {
        int chosenPoint;

        chosenPoint = int(brandom(0, this.Spawn_Locations.length() - 0.001f)); // it has to be less than the length

        return this.Spawn_Locations[chosenPoint];
    }

    void FindSpawns(String spawnType)
    {
        array<Entity @>  @spawnEntity; // use this to find possible spawns

        // spawn at a player_deathmatch
        // first i need to know all the player_deathmatch locations. Change their name as you find them until none are left.
        uint i = 0;

        @spawnEntity = @G_FindByClassname( spawnType);


        for(i=0; i<spawnEntity.size(); i++){
            this.Spawn_Locations.insertLast(spawnEntity[i].origin);

            spawnEntity[i].origin;
            //G_Print("^7"+spawnEntity.get_classname()+"!!\n"); // debug
            spawnEntity[i].set_classname("added_spawnpoint");
        }

        // rename all the info_player_deathmatches back
        @spawnEntity = @G_FindByClassname( "added_spawnpoint");

        for(i=0; i<spawnEntity.size(); i++){
            spawnEntity[i].set_classname(spawnType);
        }
    }

    void LoadCustomSpawns()
    {
        // make config a string, read into Vec3's
        String Spawns_String = G_LoadFile( "configs/server/gametypes/arc_map/" + mapName.get_string() + ".cfg" );
        int i=0;

        // get map size from the beginning
        arc_mapsize.set( Spawns_String.getToken( i ).toInt() );
        i++;

        while ( Spawns_String.getToken( i ) != "end" )
        {
            // turn into a vec3
            Vec3 add;

            add.x = Spawns_String.getToken( i ).toInt();
            i++;
            add.y = Spawns_String.getToken( i ).toInt();
            i++;
            add.z = Spawns_String.getToken( i ).toInt();
            i++;

            // add spawning location
            this.Spawn_Locations.insertLast(add);
        }
    }

    void StartState(int newState)
    {
        // get sound before switch state (can't declare in case's)
        int soundIndex = G_SoundIndex( "sounds/announcer/countdown/fight0" + int( brandom( 1, 2 ) ) );
		Client @client;

        switch (newState)
        {
            case MATCH_STATE_WARMUP:
                ARC_ControlPoint.activate();
                this.enemyExplode = false;
                this.state = MATCH_STATE_WARMUP;
                this.SetMission();
                this.ResetEnemies();
                this.ResetItems();
                this.CycleWave(); // use the first wave of enemies in warmup
                gametype.pickableItemsMask = gametype.spawnableItemsMask;
                gametype.dropableItemsMask = gametype.spawnableItemsMask;
                gametype.shootingDisabled = false;
                //instant respawn
                gametype.setTeamSpawnsystem( TEAM_ALPHA, SPAWNSYSTEM_INSTANT, 0, 0, true );

                break;

            case MATCH_STATE_COUNTDOWN: //prewave
				this.CycleWave(); // load the first wave
                //G_Print("^1PreWave!\n"); //debug
                ARC_ControlPoint.deactivate();
                this.HealPlayers(); // do this before respawn
                this.RespawnPlayers(true);
                if (this.waveIndex != this.waveCountTotal)
                {
                    this.Alert("Wave #"+this.waveIndex+" of "+this.waveCountTotal+" Incoming! ");
                }
                else
                {
                    this.Alert("Final Wave #"+this.waveIndex+" Incoming!");
                }

				// show shop for all players in the game
				for (int i=0; i < maxClients; i++)
				{
					@client = @G_GetClient(i);
					if(client.getEnt().team==TEAM_ALPHA)
					{
						GT_Command( @client, "gametypemenu", "", 0); // re-open the gametype menu
					}
				}

                this.state = MATCH_STATE_COUNTDOWN;
                this.ResetEnemies();
                gametype.pickableItemsMask = gametype.spawnableItemsMask;
                gametype.dropableItemsMask = gametype.spawnableItemsMask;
                this.portalActivated = false;
                gametype.shootingDisabled = true;
                //gametype.setTeamSpawnsystem( TEAM_ALPHA, SPAWNSYSTEM_HOLD, 0, 0, true );
				// set spawnsystem type to not respawn the players when they die
				for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
					gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_HOLD, 0, 0, true );
                this.nextThink = levelTime + WAVE_DELAYED_START;
                countDown = WAVE_DELAYED_START/1000;
                break;

            case MATCH_STATE_PLAYTIME: //during wave
                ARC_ControlPoint.activate();
                ARC_ControlPoint.spawnTimer += ARC_ControlPoint.spawnDelay*2; // delay the first point spawn more
                this.Alert("Wave Started!");
                G_AnnouncerSound( null, soundIndex, GS_MAX_TEAMS, false, null );
                this.nextThink = levelTime + 1000; //slightly delay first spawning
                this.state = MATCH_STATE_PLAYTIME;
                gametype.shootingDisabled = false;
                this.ResetEnemies();  // should already be removed in the prewave?
                this.enemyExplode = true; // explode enemies when you win
                // hold spawns during waves
				for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
					gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_HOLD, 0, 0, true );
                break;

            case MATCH_STATE_POSTMATCH: //fail a wave
                //G_Print("^1Wave Failed! \n"); //debug
                ARC_ControlPoint.deactivate();
                this.ResetItems(); // remove items on failure
                if (this.portalActivated == true)
                {
                    this.Alert("^1Portal ^7opened, Wave Failed...");

                    G_AnnouncerSound( null, deathSoundIndex, GS_MAX_TEAMS, false, null );
                }
                else
                {
                    this.Alert("Wave Failed, retrying in 5 seconds...");
                }
                this.enemyExplode = false; // silently remove enemies
                this.retries += 1;
                this.state = MATCH_STATE_POSTMATCH;
                this.nextThink = levelTime + 5000; // 5 seconds after failure before starting again
                break;

            case MATCH_STATE_WAITEXIT: // when you don't want anything to be done (done during Match Countdown (warmup -> game)
                ARC_ControlPoint.deactivate();
                this.state = MATCH_STATE_WAITEXIT;
                gametype.pickableItemsMask = 0; // disallow item pickup
                gametype.dropableItemsMask = 0; // disallow item drop
                this.ResetEnemies();
                break;

            default: break;
        }
    }

    void WaveThink()
    {
        int enemyBuffer = 1000;

        // Warmup
        if (this.state == MATCH_STATE_WARMUP)
        {
            // if there isn't max enemies spawned yet, spawn enemy after time buffer
            if ( (this.enemyCount < this.Wave_Active[MISSION_MAX_ENEMIES] ) && ( (this.nextThink) < levelTime ) )
            {
                // cycle the enemy wave if you've reached the end of the array
                if ( (this.Wave_Active[MISSION_ENEMY_TYPE] == WAVE_END ) || (this.Wave_Active[MISSION_ENEMY_TYPE] == MISSION_END) )
                {
                        this.CycleWave();
                }

                this.SpawnType( Wave_Active[MISSION_ENEMY_TYPE] );

                this.Wave_Active[MISSION_ENEMY_NUMBER] -= 1;

                if (this.Wave_Active[MISSION_ENEMY_NUMBER] == 0) // no more enemies left of this type, move on to the next part of mission
                {
                    this.Wave_Active.removeAt(MISSION_ENEMY_TYPE); // once type is removed, the enemy number is pushed over to the left in the array. delete same spot again
                    this.Wave_Active.removeAt(MISSION_ENEMY_TYPE); // this was the enemy number.
                }

                //G_Print("Active Enemies: "+enemyCount+"\n"); //debug

                this.nextThink = levelTime+enemyBuffer;
            }
        }

        // Prewave: do countdown and prepare the Mission Wave
        if (this.state == MATCH_STATE_COUNTDOWN)
        {
            this.countDownTime = this.nextThink;
            this.Countdown();

            if (this.nextThink < levelTime) // start the wave
            {
                this.CycleWave();
                // increase enemy count by 10% per player (first decrease by 90%, so 1 player is 100%)
                this.enemyCountRemaining = int((this.Wave_Active[MISSION_WAVE_ENEMIES] * (0.90f)) + (this.Wave_Active[MISSION_WAVE_ENEMIES] * (0.1f) *this.AlivePlayers()) );
                this.chestSpawned = 0;
                this.chestSpawn = CHEST_FREQUENCY;

                this.StartState(MATCH_STATE_PLAYTIME);
            }
        }

        //PlayTime: Spawn enemies / etc.
        if (this.state == MATCH_STATE_PLAYTIME)
        {
            DisplayWaveProgress();

            if (this.AlivePlayers() == 0) // if wave is failed
            {
                this.StartState(MATCH_STATE_POSTMATCH);
            }

			// If you're at the end of the wave
			if (enemyCountRemaining <= 0)
			{
				// end the wave or the mission
				if (this.Wave_Active[this.Wave_Active.length()-1] == WAVE_END)
				{
					PlayerEndWave(true); // reports / resets wave stats

					// you've beaten a wave, remove it from Mission
					while ( (this.Mission[0] != WAVE_END ) )
					{
						this.Mission.removeAt(0);
					}
					this.Mission.removeAt(0); // delete the wave_end

					this.waveIndex +=1 ;// move to next wave

					this.StartState(MATCH_STATE_COUNTDOWN);// prewave

					return;
				}
				if (this.Wave_Active[this.Wave_Active.length()-1] == MISSION_END)
				{
					//G_Print("^4YOU WIN!\n"); //debug
					PlayerEndWave(true); // reports / resets wave stats

					this.Alert("All Waves Completed!");
					ARC_ControlPoint.deactivate();
					this.ResetEnemies();

					this.Wave_Active[this.Wave_Active.length()-1] = MISSION_VICTORY;

					this.nextThink = levelTime + 5000;
					return; // don't spawn anything
				}
			}

            // if there isn't max enemies spawned yet
            if ( (this.enemyCount < this.Wave_Active[MISSION_MAX_ENEMIES] )  )
            {

                // You haven't killed all enemies yet, don't spawn enemies / anything else until nexthink
                if (this.nextThink > levelTime)
                {
                    return;
                }

                // cycle the enemy wave if you've reached the end of the array
                if ( (this.Wave_Active[MISSION_ENEMY_TYPE] == WAVE_END ) || (this.Wave_Active[MISSION_ENEMY_TYPE] == MISSION_END) )
                {
                        this.CycleWave();
                }

                // go to post game: its changed from MISSION_END to MISSION_VICTORY with timer on nextthink
                if (this.Wave_Active[this.Wave_Active.length()-1] == MISSION_VICTORY)
                {
                    this.state = MISSION_VICTORY;
                    match.launchState( match.getState() + 1 );

                    return; // don't spawn anything
                }

                // You're not at the end of the wave or mission, spawn the next enemy


                // if it's time to spawn a chest, spawn one
                if (this.chestSpawn == 0)
                {
                    if(this.chestSpawned < 3 )// max of 3 chests
                    {
                        this.SpawnType( EN_CHEST );
                        this.chestSpawn = CHEST_FREQUENCY; // frequency of chest spawning
                        this.chestSpawned += 1;
                        this.nextThink = levelTime+enemyBuffer;

                        return;
                    }
                }

                this.SpawnType( Wave_Active[MISSION_ENEMY_TYPE] );

                this.Wave_Active[MISSION_ENEMY_NUMBER] -= 1;

                if (this.Wave_Active[MISSION_ENEMY_NUMBER] == 0) // no more enemies left of this type, move on to the next part of mission
                {
                    this.Wave_Active.removeAt(MISSION_ENEMY_TYPE); // once type is removed, the enemy number is pushed over to the left in the array. delete same spot again
                    this.Wave_Active.removeAt(MISSION_ENEMY_TYPE); // this is now the enemy number
                }

                //G_Print("Active Enemies: "+enemyCount+"\n"); //debug

                this.nextThink = levelTime+enemyBuffer;
            } // end of spawning an enemy
        }

        // Fail a Wave
        if ( this.state == MATCH_STATE_POSTMATCH)
        {
            PlayerEndWave(false); // resets wave stats

            if (this.nextThink < levelTime) // delay is over
            {
                this.StartState(MATCH_STATE_COUNTDOWN); // go back to prewave
            }
        }

    }

    int AlivePlayers()
    {
        int i = 0;
        int alive = 0;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                if (!G_GetClient(i).getEnt().isGhosting())
                {
                    alive += 1;
                }
            }
        }

        return alive;
    }

    void RespawnPlayers(bool deadOnly)
    {
        int i;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                if ( (G_GetClient(i).getEnt().team == TEAM_ALPHA) )
                {

                    if ( deadOnly ) // if set, only respawn those ghosting (dead)
                    {
                        if (G_GetClient(i).getEnt().isGhosting())
                        {
                            G_GetClient(i).respawn( false );
                        }
                    }
                    else
                    {
                        G_GetClient(i).respawn( false );
                    }
                }
            }
        }

    }

    void HealPlayers() // heal up to 100 hp 50 armor
    {
        int i;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                // only respawn if in play, and if dead
                if ( (G_GetClient(i).getEnt().team == TEAM_ALPHA) && (!G_GetClient(i).getEnt().isGhosting()) )
                {
                    // if below full health
                    if ( G_GetClient(i).getEnt().health < 100)
                    {
                        G_GetClient(i).getEnt().health = 100;
                    }
                    // if armori s below, get at least 50
                    if (G_GetClient(i).armor < 50)
                    {
                        G_GetClient(i).armor = 50;
                    }
                }
            }
        }
    }

    void PlayersStatBonus(int health, int maxHealth,int armor, int maxArmor) // heal up to 100 hp
    {
        int i;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                // only respawn if in play, and if dead
                if ( (G_GetClient(i).getEnt().team == TEAM_ALPHA) && (!G_GetClient(i).getEnt().isGhosting()) )
                {
                    if (G_GetClient(i).getEnt().health < maxHealth) // give health if below limit
                    {
                        G_GetClient(i).getEnt().health += health;
                        if (G_GetClient(i).getEnt().health > maxHealth) // cap it to limit
                        {
                            G_GetClient(i).getEnt().health = maxHealth;
                        }
                    }

                    if (G_GetClient(i).armor < maxArmor) // give armor if below limit
                    {
                        G_GetClient(i).armor += armor;
                        if (G_GetClient(i).armor > maxArmor) // cap it to limit
                        {
                            G_GetClient(i).armor = maxArmor;
                        }
                    }
                }
            }
        }
    }

    void Alert(String message) // todo: parameter to set diff types of alerts
    {
        int i;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                G_CenterPrintMsg(G_GetClient(i).getEnt(), message);
                G_PrintMsg( G_GetClient(i).getEnt(), "^5-[^7"+message+"^5]-\n");
            }
        }
    }

    void SpawnType(int enemyType)
    {
        int selectSmall = int(brandom(0,2.999f)); // do this up here, can't do it during case
        int selectMed = int(brandom(0,2.999f));
        int selectPig = int(brandom(0,2.999f));

        int enemyIndex;
        Vec3 chosenSpawn = this.ChooseSpawn();

        //G_Print("^1Spawned!\n"); // debug

        // set enemyType based on pool first, if it's a pool type
        switch (enemyType)
        {
            case POOL_EASY:
                // select from all the easy enemies
                if (selectSmall == 0)
                {
                    enemyType = EN_BAT;
                }
                if (selectSmall == 1)
                {
                    enemyType = EN_WALKER;
                }
                if (selectSmall == 2)
                {
                    enemyType = EN_SNIPER;
                }
                break;
            case POOL_MED:
                if (selectMed == 0)
                {
                    enemyType = EN_SHIELD;
                }
                if (selectMed == 1)
                {
                    enemyType = EN_PIG;
                }
                if (selectMed == 2)
                {
                    enemyType = EN_WIZARD;
                }break;

            default: break;
        }
        // check for pig, doing it outside of case because pool_med returns EN_PIG pool
        if (enemyType == EN_PIG)
        {
            if (selectPig == 0)
            {
                enemyType = EN_PIG_GL;
            }
            if (selectPig == 1)
            {
                enemyType = EN_PIG_RL;
            }
            if (selectPig == 2)
            {
                enemyType = EN_PIG_PG;
            }
        }

        // make it spawn based on enemy type. add to enemyCount for successful spawns
        switch (enemyType)
        {
            case EN_BAT:
                enemyIndex = bat_spawn( chosenSpawn ); break;
            case EN_WALKER:
                enemyIndex = walker_spawn( chosenSpawn ); break;
            case EN_PIG_RL:
                enemyIndex = pig_spawn( chosenSpawn );
                if (enemyIndex != NO_AVAILABLE_ENEMIES)
                {
                    gtEnemies[enemyIndex].type = EN_PIG_RL; gtEnemies[enemyIndex].reloadDelay = 1000; gtEnemies[enemyIndex].damage = 30;
                } break;
            case EN_PIG_GL:
                enemyIndex = pig_spawn( chosenSpawn );
                if (enemyIndex != NO_AVAILABLE_ENEMIES)
                {
                    gtEnemies[enemyIndex].type = EN_PIG_GL; gtEnemies[enemyIndex].reloadDelay = 800; gtEnemies[enemyIndex].damage = 40;
                } break;
            case EN_PIG_PG:
                enemyIndex = pig_spawn( chosenSpawn );
                if (enemyIndex != NO_AVAILABLE_ENEMIES)
                {
                    gtEnemies[enemyIndex].type = EN_PIG_PG; gtEnemies[enemyIndex].reloadDelay = 200; gtEnemies[enemyIndex].damage = 10;
                } break;
            case EN_SNIPER:
                enemyIndex = sniper_spawn( chosenSpawn ); break;
            case EN_CHEST:
                enemyIndex = chest_spawn( chosenSpawn ); break;
            case EN_SHIELD:
                enemyIndex = shield_spawn( chosenSpawn ); break;
            case EN_WIZARD:
                enemyIndex = wizard_spawn( chosenSpawn ); break;
			case EN_WALKER_QUICK:
                enemyIndex = walker_quick_spawn( chosenSpawn ); break;
            default: break;
        }

        if (enemyIndex == NO_AVAILABLE_ENEMIES)
        {
            RespawnEnemyType(enemyType);
        }
        else
        {
            cEnemy @eC;
            @eC = @gtEnemies[enemyIndex];

            // debug : sometimes this is null
            if (@eC.enemyEnt != null)
            {
                // change enemy counts, but not for chests
                if (enemyType != EN_CHEST)
                {
                    this.enemyCount+=1;
                    // Limited enemies: this.enemyCountRemaining-=1;
                }

                // change stats based on difficulty
                eC.damage = int(eC.damage*float(arc_difficulty.get_integer()/100.0f));
                //eC.enemyEnt.health = eC.enemyEnt.health*float(arc_difficulty.get_integer()/100.0f);

				// change stats based on wave mods
				eC.damage = int(eC.damage*waveDamageMod);
				eC.speed = int(eC.speed*waveSpeedMod);
				eC.enemyEnt.health = int(eC.enemyEnt.health*waveHealthMod);

                eC.enemyEnt.team = TEAM_BETA; // todo: this crashed. no enemyEnt
            }
            else // for some reason it got to this point without having an enemy spawned which should be impossible
            {
                match.launchState( MATCH_STATE_POSTMATCH );
                this.Alert("^1Gametype Encountered Error: Tell xanthus1@gmail.com!");
                G_Print("enemyIndex: "+enemyIndex+"\nEnemyType: "+eC.type+"\n");
            }
        }
    }

    void RespawnEnemyType(int type)
    {
        //G_Print("^1ReSpawned!\n"); // debug
        if (match.getState() == MATCH_STATE_PLAYTIME)
        {
            //insert enemy at beginning of wave
            this.Wave_Active.insertAt(MISSION_ENEMY_TYPE,1); // put this at enemy type, when the next one is inserted, it'll be pushed to the right into MISSION_ENEMY_NUMBER
            this.Wave_Active.insertAt(MISSION_ENEMY_TYPE,type);
        }

        this.nextThink = levelTime+10; // try to spawn again
    }

    void ResetEnemies()
    {
        enemy_remove_all(this.enemyExplode); // don't explode them if you failed, just remove them. boom if you win!
        this.enemyCount = 0;
        this.countDown = NO_COUNT; //todo why do i do this?
    }

    void ResetItems()
    {
        int i = 0;
        while (@G_GetEntity(i) != null)
        {
            Entity @Ent = @G_GetEntity(i);
            if (@Ent.item != null)
            {
                Ent.freeEntity();
            }
            i++;
        }
        /* to control respawning items. I no longer use them.
        int armorDelay = 9999;
        int weaponDelay = 9999;
        int healthDelay = 9999;
        int superHealthDelay = 9999;
        int powerupDelay = 9999;

        G_Items_RespawnByType( IT_ARMOR, ARMOR_RA, armorDelay);// respawn all armors 15 s
        G_Items_RespawnByType( IT_ARMOR, ARMOR_YA, armorDelay);// respawn all armors 15 s
        G_Items_RespawnByType( IT_ARMOR, ARMOR_GA, armorDelay);// respawn all armors 15 s
        G_Items_RespawnByType( IT_ARMOR, ARMOR_SHARD, armorDelay);// respawn all armors 15 s

        G_Items_RespawnByType( IT_HEALTH, HEALTH_MEGA , superHealthDelay);
        G_Items_RespawnByType( IT_HEALTH, HEALTH_ULTRA , superHealthDelay);
        G_Items_RespawnByType( IT_HEALTH, HEALTH_LARGE , healthDelay);
        G_Items_RespawnByType( IT_HEALTH, HEALTH_MEDIUM , healthDelay);
        G_Items_RespawnByType( IT_HEALTH, HEALTH_SMALL , healthDelay);

        G_Items_RespawnByType( IT_WEAPON, WEAP_ELECTROBOLT, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_GRENADELAUNCHER, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_GUNBLADE, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_LASERGUN, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_MACHINEGUN, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_RIOTGUN, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_ROCKETLAUNCHER, weaponDelay);
        G_Items_RespawnByType( IT_WEAPON, WEAP_PLASMAGUN, weaponDelay);

        G_Items_RespawnByType( IT_AMMO, AMMO_BOLTS, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_GRENADES, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_LASERS, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_BULLETS, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_SHELLS, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_ROCKETS, weaponDelay);
        G_Items_RespawnByType( IT_AMMO, AMMO_PLASMA, weaponDelay);


        G_Items_RespawnByType( IT_POWERUP, POWERUP_QUAD, powerupDelay);
        G_Items_RespawnByType( IT_POWERUP, POWERUP_REGEN, powerupDelay);
        G_Items_RespawnByType( IT_POWERUP, POWERUP_SHELL, powerupDelay);
        */
    }

    void SetMission()
    {
        ARC_LoadConfig(arc_mission.get_string());
    }

    void Countdown()
    {
        // to use Countdown, set countDownTime and countDown first. During pre-wave, countDownTime will be set by the Wave Controller

        if ( this.countDownTime < levelTime )
        {
            this.countDown = NO_COUNT;
            return;
        }

        if ( this.countDown > 0 )
        {
            // we can't use the authomatic countdown announces because theirs are based on the
            // matchstate timelimit, and prerounds don't use it. So, fire the announces "by hand".
            int remainingSeconds = int( ( this.countDownTime - levelTime ) * 0.001f ) + 1;
            if ( remainingSeconds < 0 )
                remainingSeconds = 0;

            if ( remainingSeconds < countDown )
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
            }
        }
        //G_Print("^8FINISHED COUNTDOWN!\n"); // debug
    }

    void CountTotalWaves()
    {
        uint i = 0;
        waveCountTotal = 0;

        while (i < Mission.length())
        {
            if (Mission[i] == WAVE_END)
            {
                waveCountTotal += 1;
            }

            i++;
        }

        waveCountTotal += 1; // add one for MISSION_END
    }

    void DisplayWaveProgress()
    {
        int progress;

        progress = enemyCountRemaining; // Limited enemies: +enemyCount


        //G_Print("Wc:"+enemyCount+" WCR: "+enemyCountRemaining+" Total: "+enemyCountTotal+"\n"); //debug

        for (int i = 0; i < maxClients; i++)
        {
            if ( @G_GetClient(i) != null )
            {
                G_GetClient(i).setHUDStat( STAT_PROGRESS_OTHER, progress );
            }
        }
    }

    void CycleWave()
    {
        // clear mission wave
        this.Wave_Active = CLEAR_ARRAY;

        // set Wave_Active to Mission's firstmost wave
        int i=0;
        {
            while ( (this.Mission[i] != WAVE_END ) && (this.Mission[i] != MISSION_END) )
            {
                this.Wave_Active.insert(i, this.Mission[i]);
                i++;
            }

            Wave_Active.insertLast(Mission[i]); // add the wave_start or mission_end, whatever it was.
        }

        // set Wave Active's max enemies based on map size (+25% increase per setting)
        this.Wave_Active[MISSION_MAX_ENEMIES] = int((this.Wave_Active[MISSION_MAX_ENEMIES]*0.75f) + (this.Wave_Active[MISSION_MAX_ENEMIES] * 0.25f * arc_mapsize.get_integer()));
    }

    cWaveController()
    {
    }

    ~cWaveController()
    {
    }

}

void PlayerEndWave(bool success)
{
    int playerCount = 0; // number of players playing
    int bestDmg = 0;
    int dmgPlayer = 0; // player with the highest damage
    int bestPortals = 0;
    int portalPlayer = 0; // player with the most portals

    for (int i = 0; i< maxClients; i++)
    {
        cARCPlayer @player= @gtPlayers[i];
        Entity @playerEnt = @G_GetEntity(player.entNum);

        if (success)
        {
            if (playerEnt.team == TEAM_ALPHA)
            {
                playerCount +=1 ;
            }
            if (!playerEnt.isGhosting())
            {
                player.waveBonus += 2; // 2 bonus points for surviving
                player.gold +=1; // 1 gold for surviving
            }

            // see who has done the most damage / portals for bonuses
            if( player.waveDamage >bestDmg)
            {
                bestDmg = int(player.waveDamage);
                dmgPlayer = i;
            }
            if( player.wavePortals > bestPortals)
            {
                bestPortals = player.wavePortals;
                portalPlayer = i;
            }

            // save values
            player.totalDamage += player.waveDamage;
            player.totalPortals += player.wavePortals;
            player.totalBonus += player.waveBonus;
        }

        // reset
        player.waveDamage = 0;
        player.wavePortals = 0;
        player.waveBonus = 0;

    }

    if (success)
    {
        // only do these if not playing solo
        if (playerCount > 1)
        {
            if (bestDmg > 0)
            {
                MessagePlayers("Most damage: "+bestDmg+" by "+G_GetEntity(gtPlayers[dmgPlayer].entNum).client.get_name()+"");

                gtPlayers[dmgPlayer].totalBonus += 3;
                gtPlayers[dmgPlayer].gold +=1;
            }
            if (bestPortals > 0)
            {
                MessagePlayers("Most portals closed: "+bestPortals+" by "+G_GetEntity(gtPlayers[portalPlayer].entNum).client.get_name()+"");

                gtPlayers[portalPlayer].totalBonus += 3;
                gtPlayers[portalPlayer].gold +=1;
            }
        }
        else // playing solo
        {
            MessagePlayers("Damage: "+bestDmg+" Portals closed: "+bestPortals+" by "+G_GetEntity(gtPlayers[dmgPlayer].entNum).client.get_name()+"");
            gtPlayers[dmgPlayer].totalBonus += 3;
            gtPlayers[dmgPlayer].gold +=1;
        }
    }



}

