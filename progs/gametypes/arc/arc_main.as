/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/
int prcYesIcon;
int prcShockIcon;
int prcShellIcon;

cWaveController WaveController;
cCapturePoint ARC_ControlPoint;

const int WAVE_END = 999; // when this point is reached, all enemies must be killed before moving on to the next part
const int MISSION_END = 998; // mission end!
const int MISSION_VICTORY = 997;

int[] PRICE_ARRAY(99);

int NO_COUNT = -1;

Cvar arc_portal("arc_portal", "1", CVAR_ARCHIVE);
Cvar arc_mapsize("arc_mapsize", "1", CVAR_ARCHIVE);
Cvar arc_difficulty("arc_difficulty", "100", CVAR_ARCHIVE);
Cvar arc_mission("arc_mission", "normal", CVAR_ARCHIVE);
Cvar mapName( "mapname", "", 0 );

Cvar dmAllowPowerups( "dm_allowPowerups", "1", CVAR_ARCHIVE );

String customSpawns;

///*****************************************************************
/// NEW MAP ENTITY DEFINITIONS
///*****************************************************************


///*****************************************************************
/// LOCAL FUNCTIONS
///*****************************************************************

void ARCADE_SetVoicecommQuickMenu( Client @client )
{
	String menuStr = '';

	menuStr +=
		'"--- Arcade Menu ---" "" ' +
		'"Weapon Shop" "weapshop" ' +
		'"Armor Shop" "weapshop" ' +
		'"Legendary Weapon Shop" "legendweapshop" ' +
		'"Ability Shop" "abilityshop1" ' +
		'"Upgrade Shop" "upgradeshop" ' +
		'"Help" "helpmenu"';

	GENERIC_SetQuickMenu( @client, menuStr );
}

// a player has just died. The script is warned about it so it can account scores
void DM_playerKilled( Entity @target, Entity @attacker, Entity @inflicter )
{
    if ( @target.client == null )
        return;

    // drop your legendary if you have one (even in warmup)
    if ( gtPlayers[target.client.get_playerNum()].legendary != 0)
    {
        gtPlayers[target.client.get_playerNum()].dropLegendary();
    }

    if ( match.getState() != MATCH_STATE_PLAYTIME )
        return;



    // reduce enemy count by 25% (can't go below enemy max)
    if (WaveController.enemyCountRemaining > WaveController.Mission[MISSION_MAX_ENEMIES])
    {
        WaveController.enemyCountRemaining -= int(WaveController.Mission[MISSION_WAVE_ENEMIES] * (0.25f));

        if (WaveController.enemyCountRemaining < WaveController.Mission[MISSION_MAX_ENEMIES])
        {
            WaveController.enemyCountRemaining = WaveController.Mission[MISSION_MAX_ENEMIES];
        }
    }

    // drop items
    if ( ( G_PointContents( target.origin ) & CONTENTS_NODROP ) == 0 )
    {
        target.dropItem( AMMO_PACK_WEAK );

        if ( target.client.inventoryCount( POWERUP_QUAD ) > 0 )
        {
            target.dropItem( POWERUP_QUAD );
            target.client.inventorySetCount( POWERUP_QUAD, 0 );
        }

        if ( target.client.inventoryCount( POWERUP_SHELL ) > 0 )
        {
            target.dropItem( POWERUP_SHELL );
            target.client.inventorySetCount( POWERUP_SHELL, 0 );
        }
    }

    award_playerKilled( @target, @attacker,@inflicter );
}

///*****************************************************************
/// MODULE SCRIPT CALLS
///*****************************************************************

void ARC_LoadConfig(String configName)
{
    if ( !G_FileExists( "configs/server/gametypes/arc_" + configName + ".cfg" ) )
    {
        // this will only occur when the gametype starts and is forced to call this function without an actual config.
        //G_Print("No Config Found: Loaded Basic Config!\n");
        WaveController.Mission.insertLast(5); // number at once
        WaveController.Mission.insertLast(20); // goal
        WaveController.Mission.insertLast(POOL_EASY);
        WaveController.Mission.insertLast(999); // number of POOL_EASY to spawn ( this can be anything, limited by goal. )
        WaveController.Mission.insertLast(WAVE_END);
        WaveController.Mission.insertLast(7); // number at once?
        WaveController.Mission.insertLast(30); // goal
        WaveController.Mission.insertLast(POOL_EASY);
        WaveController.Mission.insertLast(10); // number of POOL_EASY to spawn
		WaveController.Mission.insertLast(POOL_MED);
		WaveController.Mission.insertLast(5); // number of POOL_MED to spawn
		WaveController.Mission.insertLast(POOL_EASY);
        WaveController.Mission.insertLast(999); // number of POOL_EASY to spawn ( this can be anything, limited by goal. )
        WaveController.Mission.insertLast(MISSION_END);
        return;
    }
    else // read the config and make it into an array
    {
        //G_Print("Found Config\n");
        String Config_String = G_LoadFile( "configs/server/gametypes/arc_" + configName + ".cfg" );
        WaveController.Mission = CLEAR_ARRAY; // todo: lolol
        int i=0;

        while ( Config_String.getToken( i ) != "mission_end" )
        {
            String value = Config_String.getToken( i );
            if ( value == "pool_easy") { WaveController.Mission.insertLast(POOL_EASY); }
            if ( value == "pool_med") { WaveController.Mission.insertLast(POOL_MED); }
            if ( value == "bat" )  { WaveController.Mission.insertLast(EN_BAT); }
            if ( value == "walker" ) { WaveController.Mission.insertLast(EN_WALKER); }
            if ( value == "pig" ) { WaveController.Mission.insertLast(EN_PIG); }
            if ( value == "pig_gl" ) { WaveController.Mission.insertLast(EN_PIG_GL); }
            if ( value == "pig_rl" ) { WaveController.Mission.insertLast(EN_PIG_RL); }
            if ( value == "pig_pg" ) { WaveController.Mission.insertLast(EN_PIG_PG); }
            if ( value == "sniper" ) { WaveController.Mission.insertLast(EN_SNIPER); }
            if ( value == "chest" ) { WaveController.Mission.insertLast(EN_CHEST); }
            if ( value == "shield" ) { WaveController.Mission.insertLast(EN_SHIELD); }
            if ( value == "wizard" ) { WaveController.Mission.insertLast(EN_WIZARD); }
			if ( value == "walker_quick" ) { WaveController.Mission.insertLast(EN_WALKER_QUICK); }

            if ( value == "wave_end" ) { WaveController.Mission.insertLast(WAVE_END); }

            if ( (value.toInt() > 0) && (value.toInt() < 1000) ) { WaveController.Mission.insertLast(value.toInt()); }

            i++;
        }
        WaveController.Mission.insertLast(MISSION_END);
        WaveController.ResetEnemies();

        //G_Print("Successfully loaded Config\n");

        return;
    }
}

void GT_UpdateScore()
{
    Client @client;
    for (int i=0; i < maxClients; i++)
    {
        @client = @G_GetClient(i);
        int waveDmg = int(gtPlayers[client.get_playerNum()].waveDamage); //damage done this round so far
        int totalDmg = int(gtPlayers[client.get_playerNum()].totalDamage); // damage done on successful rounds so far
        int wavePort = gtPlayers[client.get_playerNum()].wavePortals; // portals closed this wave
        int totalPort = gtPlayers[client.get_playerNum()].totalPortals; // portals closed this wave
        int waveBonus = gtPlayers[client.get_playerNum()].waveBonus;
        int totalBonus = gtPlayers[client.get_playerNum()].totalBonus;
        // score: 1% of damage + portals closed + bonus
        client.stats.setScore( (int( (waveDmg + totalDmg) * 0.002f)) + (int (wavePort + totalPort)) + int(waveBonus + totalBonus) );
    }
}

bool GT_Command( Client @client, const String &in cmdString, const String &in argsString, int argc )
{
    // for adding custom spawns
    if ( cmdString == "addspawn")
    {
        Vec3 here = client.getEnt().origin;
        customSpawns = customSpawns + ""+here.x+" "+here.y+" "+here.z+" \n";
        G_Print("Added Spawn!");
    }
    if (cmdString == "savespawncfg")
    {
        // store mapsize at the beginning and tell the cfg where to end
        customSpawns = ""+ arc_mapsize.get_integer() +" "+ customSpawns + "end";
        G_WriteFile( "configs/server/gametypes/arc_map/" + mapName.get_string()+ ".cfg", customSpawns);
        G_Print("Saved Spawns!");
    }
    if ( cmdString == "debug")
    {
        //
        /*
        G_Print("^8Retries:"+WaveController.retries+"\n"); //debug
        client.getEnt().health = 300;
        */
        if (gametype.dropableItemsMask != 0 )
        {
            int randWeap = Loot.LegendaryPick(gtPlayers[client.get_playerNum()].legendary);
            while (randWeap == gtPlayers[client.get_playerNum()].legendary)
            {
                randWeap = int(brandom(WEAP_GUNBLADE,WEAP_ELECTROBOLT+0.999f));
            }
            Entity @legItem = @Loot.DropItem( client.getEnt(), client.getEnt().origin, randWeap);
            Legendary_Spawn(@legItem, randWeap );
			legItem.delay = 0;

            randWeap = WEAP_MACHINEGUN;
            while (randWeap < WEAP_INSTAGUN)
            {
                client.inventoryGiveItem( randWeap );
                randWeap++;
            }
        }
		gtPlayers[client.get_playerNum()].gold += 20;


        //client.getEnt().dropItem( POWERUP_SHELL);
        //client.getEnt().dropItem( POWERUP_REGEN);
    }
    if ( cmdString == "classAction1")
    {
        gtPlayers[client.get_playerNum()].useAbility(1);
    }
    if ( cmdString == "classAction2")
    {
        gtPlayers[client.get_playerNum()].useAbility(2);
    }
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
                if (client.weapon != gtPlayers[client.get_playerNum()].legendary)
                {
                    GENERIC_DropCurrentWeapon( client, true );
                }
                else
                {

                    Entity @legItem = @GENERIC_DropCurrentWeapon( client, true );//client.getEnt().dropItem(client.weapon);
                    Legendary_Spawn(@legItem, client.weapon );

                    gtPlayers[client.get_playerNum()].legendary = 0;
                }
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
    else if ( cmdString == "cvarinfo" )
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
    else if ( cmdString == "callvotevalidate" )
    {
        String votename = argsString.getToken( 0 );

        if (votename == "arc_portal")
        {
            int arg = argsString.getToken( 1 ).toInt();

            if (arg == arc_portal.get_integer() )
            {
                G_PrintMsg( client.getEnt(), "^1Already set to "+arg+"\n");
                return false;
            }
            if ( (arg<0) || (arg>3) )
            {
                G_PrintMsg( client.getEnt(), "^1Pick a value between 0 and 3\n" );
                return false;
            }
            else
            {
                return true;
            }
        }

        if (votename == "arc_mapsize")
        {
            int arg = argsString.getToken( 1 ).toInt();

            if (arg == arc_mapsize.get_integer() )
            {
                G_PrintMsg( client.getEnt(), "^1Already set to "+arg+"\n");
                return false;
            }
            if ( (arg>=-1) && (arg<=4) )
            {
                return true;
            }
            else
            {
                G_PrintMsg( client.getEnt(), "^1Pick a value between -1 and 4\n" );
                return false;
            }
        }

        if (votename == "arc_mission")
        {
            String arg = argsString.getToken( 1 );

            if ( match.getState() != MATCH_STATE_WARMUP)
            {
                G_PrintMsg( client.getEnt(), "^1This vote only available during warmup\n" );
                return false;
            }

            // todo: don't validate vote if it's already current mission

            if ( G_FileExists( "configs/server/gametypes/arc_" + arg + ".cfg" ) )
            {
                return true;
            }
            else
            {
                G_PrintMsg( client.getEnt(), "^1Config not found\n" );
                return false;
            }
        }

        if (votename == "arc_difficulty")
        {
            int arg = argsString.getToken( 1 ).toInt();

            if (arg == arc_difficulty.get_integer() )
            {
                G_PrintMsg( client.getEnt(), "^1Already set to "+arg+"\n");
                return false;
            }
            if ( (arg>=50) && (arg<=300) )
            {
                return true;
            }
            else
            {
                G_PrintMsg( client.getEnt(), "^1Pick a value between 50 and 300\n" );
                return false;
            }
        }

    }
    else if ( cmdString == "callvotepassed" )
    {
        String votename = argsString.getToken( 0 );
		if ( votename == "dm_allow_powerups" )
        {
        	if( argsString.getToken( 1 ).toInt() > 0 )
            	dmAllowPowerups.set( 1 );
            else
            	dmAllowPowerups.set( 0 );

            // force a match restart to update
            match.launchState( MATCH_STATE_POSTMATCH );
            return true;
        }

        if ( votename == "arc_portal" )
        {
            int arg = argsString.getToken( 1 ).toInt();

            if (arg == 0)
            {
                arc_portal.set( 0 );
                ARC_ControlPoint.deactivate();
                ARC_ControlPoint.enabled = false;
            }
            else
            {
                arc_portal.set( 1 );
                ARC_ControlPoint.activate();
                ARC_ControlPoint.enabled = true;
                switch (arg)
                {
                    case 1: /* 5/30 */ ARC_ControlPoint.spawnDelay = 5000; ARC_ControlPoint.doomDelay = 30000; break;
                    case 2: /* 3/12 */ ARC_ControlPoint.spawnDelay = 3000; ARC_ControlPoint.doomDelay = 12000; break;
                    case 3: /* 2/8 */ ARC_ControlPoint.spawnDelay = 2000; ARC_ControlPoint.doomDelay = 8000; break;
                    default: break;
                }
            }
        }
        if ( votename == "arc_mapsize" )
        {
            int arg = argsString.getToken( 1 ).toInt();

            arc_mapsize.set( arg );
            WaveController.mapSize = arg;

            WaveController.CycleWave(); // reset up maxenemies
        }
        if (votename == "arc_mission")
        {
            //String arg = argsString.getToken( 1 );
            String arg = argsString.getToken( 1 );
            arc_mission.set(arg);
            ARC_LoadConfig(arg);
        }
        if (votename == "arc_difficulty")
        {
            int arg = argsString.getToken( 1 ).toInt();

            arc_difficulty.set(arg);
        }

    }
    else if ( cmdString == "gametypemenu" )
    {
        client.execGameCommand( "mecu \"Shop ( Esc > Arcade Co-op Options )\" Weapon_Shop \"weapshop\" Armor_Shop \"armorshop\" Legendary_Weapon_Shop \"legendweapshop\" Ability_Shop \"abilityshop1\" Upgrade_Shop \"upgradeshop\" Refund \"refundmenu\"    Help \"helpmenu\" " );

        return true;
    }
    else if (cmdString == "weapshop")
    {
        client.execGameCommand( "mecu \"Weapon_Shop | Gold:"+gtPlayers[client.get_playerNum()].gold+"\" Riotgun:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_RIOTGUN]+" \"buy "+(WEAP_NORMAL+WEAP_RIOTGUN)+" \" "
			+"RocketLauncher:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_ROCKETLAUNCHER]+" \"buy "+(WEAP_NORMAL+WEAP_ROCKETLAUNCHER)+" \" "
			+"Machinegun:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_MACHINEGUN]+" \"buy "+(WEAP_NORMAL+WEAP_MACHINEGUN)+" \" "
			+"GrenadeLauncher:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_GRENADELAUNCHER]+" \"buy "+(WEAP_NORMAL+WEAP_GRENADELAUNCHER)+" \" "
			+"PlasmaGun:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_PLASMAGUN]+" \"buy "+(WEAP_NORMAL+WEAP_PLASMAGUN)+" \" "
			+"LaserGun:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_LASERGUN]+" \"buy "+(WEAP_NORMAL+WEAP_LASERGUN)+" \" "
			+"Electrobolt:"+PRICE_ARRAY[WEAP_NORMAL+WEAP_ELECTROBOLT]+" \"buy "+(WEAP_NORMAL+WEAP_ELECTROBOLT)+" \" "
			+"Back \"gametypemenu\" ");

    }
	else if (cmdString == "armorshop")
    {
        client.execGameCommand( "mecu \"Armor_Shop | Gold:"+gtPlayers[client.get_playerNum()].gold+"\" \" Green (up to 100): "+PRICE_ARRAY[ARCADE_ARMOR_GREEN]+"\" \"buy "+ARCADE_ARMOR_GREEN+" \" "
			+" \"Yellow (up to 125): "+PRICE_ARRAY[ARCADE_ARMOR_YELLOW]+"\" \"buy "+ARCADE_ARMOR_YELLOW+" \" "
			+" \"Red (200): "+PRICE_ARRAY[ARCADE_ARMOR_RED]+" \" \"buy "+ARCADE_ARMOR_RED+" \" "
			+"Back \"gametypemenu\" ");
    }
	else if (cmdString == "legendweapshop")
    {
        client.execGameCommand( "mecu \"Legendary_Weapon_Shop | Gold:"+gtPlayers[client.get_playerNum()].gold+"\" Riotgun:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_RIOTGUN]+" \"buy "+(WEAP_LEGENDARY+WEAP_RIOTGUN)+" \" "
			+"RocketLauncher:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_ROCKETLAUNCHER]+" \"buy "+(WEAP_LEGENDARY+WEAP_ROCKETLAUNCHER)+" \" "
			+"Machinegun:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_MACHINEGUN]+" \"buy "+(WEAP_LEGENDARY+WEAP_MACHINEGUN)+" \" "
			+"GrenadeLauncher:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_GRENADELAUNCHER]+" \"buy "+(WEAP_LEGENDARY+WEAP_GRENADELAUNCHER)+" \" "
			+"PlasmaGun:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_PLASMAGUN]+" \"buy "+(WEAP_LEGENDARY+WEAP_PLASMAGUN)+" \" "
			+"LaserGun:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_LASERGUN]+" \"buy "+(WEAP_LEGENDARY+WEAP_LASERGUN)+" \" "
			+"Electrobolt:"+PRICE_ARRAY[WEAP_LEGENDARY+WEAP_ELECTROBOLT]+" \"buy "+(WEAP_LEGENDARY+WEAP_ELECTROBOLT)+" \" "
			+"Back \"gametypemenu\" ");
    }
    else if (cmdString == "abilityshop1")
    {
        client.execGameCommand( "mecu \"Ability_Shop (Max:2) | Gold:"+gtPlayers[client.get_playerNum()].gold+" \" "
		+"Weapon_Smith:"+PRICE_ARRAY[ABILITY_SMITH]+" \"buy "+ABILITY_SMITH+" \" "
		+"Shield:"+PRICE_ARRAY[ABILITY_SHIELD]+" \"buy "+ABILITY_SHIELD+" \" "
		+"Double_Jump:"+PRICE_ARRAY[ABILITY_DOUBLEJ]+" \"buy "+ABILITY_DOUBLEJ+" \" "
		+"Explosive_Push:"+PRICE_ARRAY[ABILITY_PUSH]+" \"buy "+ABILITY_PUSH+" \" "
		+"Jackfly's_Wings:"+PRICE_ARRAY[ABILITY_FLY]+" \"buy "+ABILITY_FLY+" \" "
		+"Back \"gametypemenu\" ");
    }
    else if (cmdString == "upgradeshop")
    {
        client.execGameCommand( "mecu \"Upgrade_Shop (Max:1) | Gold:"+gtPlayers[client.get_playerNum()].gold+"\" "
		+"Faster_Dash:"+PRICE_ARRAY[UP_DASH]+" \"buy "+UP_DASH+" \" "
		+"Regen:"+PRICE_ARRAY[UP_REGEN]+" \"buy "+UP_REGEN+" \" "
		+"Speed_Rage:"+PRICE_ARRAY[UP_RAGE]+" \"buy "+UP_RAGE+" \" "
		+"Back \"gametypemenu\" ");
    }
    else if (cmdString == "refundmenu")
    {
        client.execGameCommand( "mecu \"Refund_Menu\" SwitchAbilities \"switchabilities\" Ability1 \"refund ability1\" Ability2 \"refund ability2\" Upgrade \"refund upgrade\" All \"refund all\"");
    }
    else if (cmdString == "switchabilities")
    {
        // Swap abilities
        int temp = gtPlayers[client.get_playerNum()].abilityOne;
        gtPlayers[client.get_playerNum()].abilityOne = gtPlayers[client.get_playerNum()].abilityTwo;
        gtPlayers[client.get_playerNum()].abilityTwo = temp;

        client.printMessage("^7Abilities 1 and 2 were switched!\n");
    }
    else if (cmdString == "refund")
    {
        int refunded = 0;

        if ( argsString.getToken(0) == "ability1")
        {
            if (gtPlayers[client.get_playerNum()].abilityOne > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].abilityOne];
                gtPlayers[client.get_playerNum()].abilityOne = 0;

                client.printMessage("^7Ability1 was refunded for: ^3"+refunded+" gold ^7.\n");
            }
        }

        if ( argsString.getToken(0) == "ability2")
        {
            if (gtPlayers[client.get_playerNum()].abilityTwo > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].abilityTwo];
                gtPlayers[client.get_playerNum()].abilityTwo = 0;

                client.printMessage("^7Ability2 was refunded for: ^3"+refunded+" gold ^7.\n");
            }
        }

        if ( argsString.getToken(0) == "upgrade")
        {
            if (gtPlayers[client.get_playerNum()].upgrade > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].upgrade];
                gtPlayers[client.get_playerNum()].upgrade = 0;

                client.printMessage("^7Upgrade was refunded for: ^3"+refunded+" gold ^7.\n");
            }
        }

        if ( argsString.getToken(0) == "all")
        {
            if (gtPlayers[client.get_playerNum()].abilityOne > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].abilityOne];
                gtPlayers[client.get_playerNum()].abilityOne = 0;
            }
            if (gtPlayers[client.get_playerNum()].abilityTwo > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].abilityTwo];
                gtPlayers[client.get_playerNum()].abilityTwo = 0;
            }
            if (gtPlayers[client.get_playerNum()].upgrade > 0)
            {
                refunded += PRICE_ARRAY[gtPlayers[client.get_playerNum()].upgrade];
                gtPlayers[client.get_playerNum()].upgrade = 0;
            }

            client.printMessage("^7All upgrades were refunded for: ^3"+refunded+" gold ^7.\n");
        }

        if (refunded > 0)
        {
            gtPlayers[client.get_playerNum()].gold += refunded;
        }
    }
    else if ( cmdString == "buy")
    {
		// cannot buy during countdown before game starts
		if(match.getState() == MATCH_STATE_COUNTDOWN)
		{
			return false;
		}
        String purchase;
        String explain;

        //check gold
        if (gtPlayers[client.get_playerNum()].gold < PRICE_ARRAY[argsString.getToken(0).toInt()])
        {
            client.printMessage("^7Not enough ^1gold^7!\n");
            return true;
        }

        // AbilityShops
        if ( (argsString.getToken(0).toInt() > 10) && (argsString.getToken(0).toInt()<20) )
        {
            // see if player already has this ability
            if (gtPlayers[client.get_playerNum()].abilityTwo == argsString.getToken(0).toInt())
            {
                client.printMessage("^1You already have this ability on ^3classAction1^1!\n");
                return true;
            }
            if (gtPlayers[client.get_playerNum()].abilityTwo == argsString.getToken(0).toInt())
            {
                client.printMessage("^1You already have this ability on ^3classAction2^1!\n");
                return true;
            }

            // see if player has free ability slots
            int abilitySlot = 1;
            String abilityString = "classAction1"; //store which command the ability goes to
            if (gtPlayers[client.get_playerNum()].abilityOne != 0)
            {
                abilitySlot = 2; // choose second slot
                abilityString = "classAction2";

                if (gtPlayers[client.get_playerNum()].abilityTwo != 0)
                {
                    client.printMessage("^1You already have two abilities! Use refund on the menu if you want to change\n");
                    return true;
                }
            }

            explain = "^7Use ^3"+abilityString+"^7 to "; // start explaination string

            switch (argsString.getToken(0).toInt())
            {
                case ABILITY_PUSH: purchase = "Explosive Push"; explain += "hurt and push away nearby enemies"; break;
                case ABILITY_FLY: purchase = "Jackfly's Wings"; explain += "fly"; break;
                case ABILITY_SHIELD: purchase = "Shield"; explain += "activate a temporary shield"; break;
                case ABILITY_DOUBLEJ: purchase = "Double Jump"; explain += "double jump";break;
                case ABILITY_SMITH: purchase = "Smithing"; explain += "smith your current weapon (GB will smith a random). Small chance of smithing legendary";break;
                default: break;
            }

            // buy the ability
            if (abilitySlot == 1)
            {gtPlayers[client.get_playerNum()].abilityOne = argsString.getToken(0).toInt();}
            else{gtPlayers[client.get_playerNum()].abilityTwo = argsString.getToken(0).toInt();}
        }
		// Armor shop
        if ( (argsString.getToken(0).toInt() > 20) && (argsString.getToken(0).toInt()<30) )
        {
			switch(argsString.getToken(0).toInt()){
				case ARCADE_ARMOR_GREEN: purchase="Green Armor"; client.inventoryGiveItem( ARMOR_GA ); break;
				case ARCADE_ARMOR_YELLOW: purchase="Yellow Armor"; client.inventoryGiveItem( ARMOR_YA ); break;
				case ARCADE_ARMOR_RED: purchase="Red Armor"; client.armor=200; break;
			}
		}
        // weapons
        if ( (argsString.getToken(0).toInt() > 30) && (argsString.getToken(0).toInt()<40) )
        {
			int weap = argsString.getToken(0).toInt() - WEAP_NORMAL;
			switch ( weap){
				case WEAP_MACHINEGUN: purchase="Machinegun"; break;
				case WEAP_RIOTGUN: purchase="Riotgun"; break;
				case WEAP_GRENADELAUNCHER: purchase="Grenade Launcher"; break;
				case WEAP_ROCKETLAUNCHER: purchase="Rocket Launcher"; break;
				case WEAP_PLASMAGUN: purchase="Plasma Gun"; break;
				case WEAP_LASERGUN: purchase="Laser Gun"; break;
				case WEAP_ELECTROBOLT: purchase="Electrobolt"; break;
				default: break;
			}
			// give multiple times to have max ammo
			client.inventoryGiveItem( weap,1);
			client.inventoryGiveItem( weap,1);
			client.inventoryGiveItem( weap,1);
			client.inventoryGiveItem( weap,1);
        }

        // upgrades
        if ( (argsString.getToken(0).toInt() > 40) && (argsString.getToken(0).toInt() <50) )
        {
            if (gtPlayers[client.get_playerNum()].upgrade != 0)
            {
                client.printMessage("^1You already have an upgrade! Use reset on the menu if you want to change\n");
                return true;
            }
            switch (argsString.getToken(0).toInt())
            {
                case UP_DASH: purchase = "Increased Dash Speed"; client.set_pmoveDashSpeed(600); break;
                case UP_REGEN: purchase = "Regen"; explain += "Regen up to 125 health"; break;
                case UP_RAGE: purchase = "Rage"; explain += "Get quad damage by moving fast"; break;
                default: break;
            }

            gtPlayers[client.get_playerNum()].upgrade = argsString.getToken(0).toInt();
        }

		// legendary weapons
		if ( (argsString.getToken(0).toInt() > 60) && (argsString.getToken(0).toInt()<70) )
        {
			// spawn a weapon , give it legendary status, and immediately pickup / remove
			int weap = argsString.getToken(0).toInt() - WEAP_LEGENDARY;
			Entity @legItem = @Loot.DropItem( client.getEnt(), client.getEnt().origin, weap);
            Entity @legWeap = Legendary_Spawn(@legItem, weap );
			legWeap.delay=0; // instant pickup on legendary object
			legItem.freeEntity(); // free weapon object

			purchase = "Legendary weapon";
		}

        client.printMessage("^7You bought ^3"+purchase+"^7!\n");
        client.printMessage(""+explain+"\n");

        gtPlayers[client.get_playerNum()].gold -= PRICE_ARRAY[argsString.getToken(0).toInt()];

		GT_Command( @client, "gametypemenu", "", 0); // re-open the gametype menu
    }
    else if ( cmdString == "helpmenu")
    {
        client.printMessage("\n");
        client.printMessage("^6----GENERAL HELP----\n");
        client.printMessage("^6Kill a certain number of enemies to beat a wave\n");
        client.printMessage("^6Get to portals before they activate (you'll fail the wave)\n");
        client.printMessage("^6Gain gold by doing well and getting score\n");
        client.printMessage("^6Buy upgrades in the Arcade options menu (use ^3LeftShift^6 for quick menu by default)\n");
        client.printMessage("^6Bind ^3classAction1^6 and ^3classAction2^6 to use abilities!\n");
        client.printMessage("^6----END OF GENERAL HELP----\n");
        client.printMessage("\n");
    }
    return false;
}

// When this function is called the weights of items have been reset to their default values,
// this means, the weights *are set*, and what this function does is scaling them depending
// on the current bot status.
// Player, and non-item entities don't have any weight set. So they will be ignored by the bot
// unless a weight is assigned here.
/*
bool GT_UpdateBotStatus( Entity @self )
{
    return GENERIC_UpdateBotStatus( self );
}
*/

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
    int i, carrierIcon, readyIcon;

    @team = @G_GetTeam( TEAM_ALPHA ); // Debug: was alpha

    // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
    entry = "&t " + int( TEAM_ALPHA ) + " " + team.stats.score + " 0 ";
    if ( scoreboardMessage.len() + entry.len() < maxlen )
        scoreboardMessage += entry;

    for ( i = 0; @team.ent( i ) != null; i++ )
    {
        @ent = @team.ent( i );

        if ( ( ent.effects & EF_QUAD ) != 0 )
            carrierIcon = prcShockIcon;
        else if ( ( ent.effects & EF_SHELL ) != 0 )
            carrierIcon = prcShellIcon;
        else
            carrierIcon = 0;

        if ( ent.client.isReady() )
            readyIcon = prcYesIcon;
        else
            readyIcon = 0;

		int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;

        entry = "&p " + playerID + " " + playerID + " " + ent.client.clanName + " " + ent.client.stats.score + " "
                +gtPlayers[ent.client.get_playerNum()].gold+ " " + ent.client.ping
                + " " + carrierIcon + " " + readyIcon + " ";

        if ( scoreboardMessage.len() + entry.len() < maxlen )
            scoreboardMessage += entry;
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
        int targetNum = args.getToken( 0 ).toInt(); // target entNum
        Entity @targetEnt = G_GetEntity(targetNum);
        int dmg = args.getToken( 1 ).toInt(); // damage

        if ( (@client != null) && (@targetEnt!= null) )
        {
            // report enemy damages to cARCPlayer
            if ( @targetEnt == @gtEnemies[targetEnt.count].enemyEnt )
            {
                gtPlayers[client.get_playerNum()].waveDamage += dmg;
				gtPlayers[client.get_playerNum()].goldDmg+= dmg;
            }

			// Team attack: give player some hp / armor back and display message
			//Bugfix : this sometimes does a null pointer. Not sure why, but atm, just don't do this if there's not target.client
            // it only runs it for TEAM_ALPHA Entities (maybe arc_portal?)
            if (@targetEnt.client != null)
            {
                if ( (targetEnt.team == TEAM_ALPHA) && (@targetEnt != @client.getEnt() ) )// don't count selfdamage
                {
                    // Display different message if healing teammate
                    if ( (gtPlayers[client.get_playerNum()].legendary == WEAP_LASERGUN) && (client.weapon == WEAP_LASERGUN) )
                    {
                        G_CenterPrintMsg(client.getEnt(),"Healing "+targetEnt.client.get_name()+" - HP: "+int(targetEnt.health)+"\n");
                    }
                    else
                    {
                        G_CenterPrintMsg(client.getEnt(),"Don't attack ^5TEAMMATES^7, attack the ^1ENEMIES!\n");
                    }

                    // heal target based on armor
                    // todo: possibly fix the healing when you had armor, but the damage removes it all.
                    // it currently will just put it into health and not give armor back (if you would still have armor left
                    // if only 25% was taken away). You will survive the same amount of damage, but it's just a slight mis-alignment
                    // between health and armor for that 1 hit.
                    float teamProt = 1.0f; // give them 100% damage done back

                    if (targetEnt.client.armor > 0)
                    {
                        targetEnt.health += (float(dmg)*teamProt) * (1.0f/3.0f); // heal 1/3rd towards health
                        targetEnt.client.armor += (float(dmg)*teamProt) * (2.0f/3.0f); // heal 2/3rds of armor
                        //client.printMessage("^8Heal : "+(float(dmg)*teamProt) * (1.0f/3.0f)+"/"+(dmg*teamProt) * (2.0f/3.0f)+"\n"); // debug
                    }
                    else
                    {
                        targetEnt.health += float(dmg)*teamProt;
                        //client.printMessage("^8Heal: "+(float(dmg)*teamProt)+"/0 \n"); // debug
                    }

                }
            }

            // player dmg
            gtPlayers[client.get_playerNum()].dmg(@client.getEnt() , @targetEnt, dmg);
            // do legendary stuff
            Legendary_Dmg( @client.getEnt() , @targetEnt, dmg);
        }
        else //if a client didn't do damage, don't hurt the enemy
        {
            // don't count when crushed by enemies ( dmg = 100,000 )
            if ( (@targetEnt == @gtEnemies[targetEnt.count].enemyEnt) && (dmg!=100000) )
            {
                //G_Print("Self Damage!"+dmg+"\n"); // debug

                targetEnt.health += dmg;
            }
        }

    }
    else if ( score_event == "kill" ) // this is also called when you kill enemies
    {
        Entity @attacker = null;

        if ( @client != null )
            @attacker = @client.getEnt();

        int arg1 = args.getToken( 0 ).toInt();
        int arg2 = args.getToken( 1 ).toInt();

        // target, attacker, inflictor
        DM_playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );
    }
    else if ( score_event == "award" )
    {
    }
    else if ( score_event == "pickup")
    {
		// armors / megahealth will give bonuses to the team (balance from the player who picked it up so they don't get extra)
		
        bool hasClient = true;
        if (@client == null)
        {
            hasClient = false;
        }

        String arg1 = args.getToken( 0 );

        if (arg1 == "item_armor_ga")
        {
            if (hasClient)
            {
                //client.printMessage("GA Bonus!\n");
                client.armor -= 15;
            }
            // give 15 armor to all, up to 100
			WaveController.PlayersStatBonus(0,0,15,100);
        }
        if (arg1 == "item_armor_ya")
        {
            if (hasClient)
            {
                //client.printMessage("YA Bonus!\n");
                client.armor -= 25;
            }
			// give 25 armor to all, up to 125
            WaveController.PlayersStatBonus(0,0,25,125);
        }
        if (arg1 == "item_armor_ra")
        {
            if (hasClient)
            {
                //client.printMessage("RA Bonus!\n");
                client.armor -= 35;
            }
			// give 35 armor to all, up to 150
            WaveController.PlayersStatBonus(0,0,35,150);
        }
        if ( (arg1 == "item_health_mega") || (arg1 == "item_health_ultra") )
        {
            if (hasClient)
            {
                //client.printMessage("Mega Bonus!\n");
				client.getEnt().health-=50;
            }
			// give 50 hp to all up to 200
            WaveController.PlayersStatBonus(50,200,0,0);
        }

    }
    else if ( score_event == "enterGame" )
    {
        gtPlayers[client.get_playerNum()].reset();
    }
}

// a player is being respawned. This can happen from several ways, as dying, changing team,
// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
void GT_PlayerRespawn( Entity @ent, int old_team, int new_team )
{
	cARCPlayer @player = @gtPlayers[ent.client.get_playerNum()];
    if ( new_team == TEAM_SPECTATOR )
    {
        if ( player.legendary != 0)
        {
            Entity @legItem;
            @legItem = @ent.dropItem(player.legendary); // count is the item type
            if (@legItem != null) // sometimes you can't spawn an item (countdown)
            {
                legItem.origin = player.lastLocation; // move to the last spot the player was
                Legendary_Spawn(@legItem, player.legendary); // respawn the legendary thing
            }
        }

        player.reset(); //lose everything when you spec / somebody connects to server
    }

    if (new_team == TEAM_PLAYERS)  // force to alpha team
    {
        ent.team = TEAM_ALPHA;
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
        ent.client.inventoryGiveItem( WEAP_RIOTGUN);
        ent.client.inventoryGiveItem( WEAP_RIOTGUN);

        if ( match.getState() <= MATCH_STATE_WARMUP )
        {
			// 25 gold during warmup
			gtPlayers[ent.client.get_playerNum()].gold=25;

            ent.client.inventoryGiveItem( ARMOR_YA );
			ent.client.inventoryGiveItem( ARMOR_YA );

			// give all weapons
            for ( int i = WEAP_GUNBLADE + 1; i < WEAP_TOTAL; i++ )
            {
                if ( i == WEAP_INSTAGUN ) // dont add instagun...
                    continue;

                ent.client.inventoryGiveItem( i );

                if ( match.getState() <= MATCH_STATE_WARMUP )
                {
                    @item = @G_GetItem( i );

                    @ammoItem = item.weakAmmoTag == AMMO_NONE ? null : @G_GetItem( item.weakAmmoTag );
                    if ( @ammoItem != null )
                        ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );

                    @ammoItem = @G_GetItem( item.ammoTag );
                    if ( @ammoItem != null )
                        ent.client.inventorySetCount( ammoItem.tag, ammoItem.inventoryMax );
                }
            }
        }
		else
		{
			ent.health = 100;
			ent.client.inventoryGiveItem( ARMOR_GA );
		}
    }

	ent.client.selectWeapon( -1 ); // auto-select best weapon in the inventory

	ARCADE_SetVoicecommQuickMenu( ent.client ); // set quickmenu for shops

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

    // start the game if you're the only one and you're ready. and quit game if there are no players
    int players = 0;
    int ready = 0;
    for (int i = 0; i < maxClients; i++)
    {
        Client @client = @G_GetClient( i );

        if (client.team != TEAM_SPECTATOR)
        {
            players++;
        }
        if (client.isReady())
        {
            ready += 1;
        }

    }

    if (match.getState() == MATCH_STATE_WARMUP)
    {
        if ( (players > 0) && (ready == players)  ) // at least 1 player, and all are ready
        {
            match.launchState( match.getState() + 1 );
            //G_Print("^1Solo Started!"); //debug
        }
    }

    if (match.getState() == MATCH_STATE_COUNTDOWN) //
    {
        if ( (players == 0)  )
        {
            match.launchState( MATCH_STATE_WARMUP );
            match.setClockOverride( levelTime+(1000*60) ); // do another minute of warmup
        }
    }

    if (match.getState() == MATCH_STATE_PLAYTIME)
    {
        if (players == 0)
        {
            match.launchState (match.getState() + 1);
            WaveController.Alert("Not enough players, match aborted");
        }
    }

	GENERIC_Think();

	GT_UpdateScore(); //update score based on damage and stuff


	WaveController.WaveThink();

	//TeamIndicatorFollow();
	PlayerThink();

    // keep quad/Shell at max time. change classname so you can cycle through, then change back when done
    array<Entity @> @powerUp;
    @powerUp = @G_FindByClassname( "item_quad");
    for(uint i=0;i<powerUp.size(); i++)
    {
        powerUp[i].count = 15;
        powerUp[i].set_classname("r_item_quad");
    }
    @powerUp = @G_FindByClassname( "item_warshell");
    for(uint i=0;i<powerUp.size(); i++)
    {
        powerUp[i].count = 15;
        powerUp[i].set_classname("r_item_warshell");
    }
    // change classnames back
    @powerUp = @G_FindByClassname( "r_item_quad");
    for(uint i=0;i<powerUp.size(); i++)
    {
        powerUp[i].set_classname("item_quad");
    }
    @powerUp = @G_FindByClassname( "r_item_warshell");
    for(uint i=0;i<powerUp.size(); i++)
    {
        powerUp[i].set_classname("item_warshell");
    }

    Legendary_Think();

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
        WaveController.StartState(MATCH_STATE_WARMUP);
        GENERIC_SetUpWarmup();
		SpawnIndicators::Create( "info_player_deathmatch", TEAM_ALPHA );
        break;

    case MATCH_STATE_COUNTDOWN:
        GENERIC_SetUpCountdown();
        WaveController.StartState(MATCH_STATE_WAITEXIT); // don't spawn enemies during countdown
		SpawnIndicators::Delete();
        break;

    case MATCH_STATE_PLAYTIME:
        WaveController.CountTotalWaves();
        WaveController.ResetItems(); // remove items from warmup
        WaveController.StartState(MATCH_STATE_COUNTDOWN); // go to pre-wave
        WaveController.missionStartTime = levelTime;
        ResetARCPlayers(); // clear stats going into the game
        Loot.Reset();
        WaveController.RespawnPlayers(false); // respawn all players no matter what

        //GENERIC_SetUpMatch(); removed this so it wouldn't display FIGHT! I handle everything else
        break;

    case MATCH_STATE_POSTMATCH:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        WaveController.ResetEnemies();
        //todo: I used to make sure active was >2. Not sure why. If everything is fine, remove this
        if (WaveController.state == MISSION_VICTORY)
        {
            int mins;
            int secs;

            mins = (levelTime - WaveController.missionStartTime)/1000/60;
            secs = (levelTime - WaveController.missionStartTime)/1000 % 60;

            WaveController.Alert("Mission \""+arc_mission.get_string()+"\" Completed in ^3"+ mins + "^7 minutes and ^3"+ secs +"^7 seconds with ^3"+WaveController.retries+" ^7retries!");
            ShowARCStats();
        }
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
    WaveController.Init();

    ARC_ControlPoint.Init();
    InitARCPlayers();

    // set prices
    PRICE_ARRAY[ABILITY_SHIELD] = 5;
    PRICE_ARRAY[ABILITY_DOUBLEJ] = 5;
    PRICE_ARRAY[ABILITY_PUSH] = 10;
    PRICE_ARRAY[ABILITY_FLY] = 15;
    PRICE_ARRAY[ABILITY_SMITH] = 5;
    PRICE_ARRAY[UP_DASH] = 10;
    PRICE_ARRAY[UP_REGEN] = 10;
    PRICE_ARRAY[UP_RAGE] = 15;
	PRICE_ARRAY[ARCADE_ARMOR_GREEN] = 1;
	PRICE_ARRAY[ARCADE_ARMOR_YELLOW] = 2;
	PRICE_ARRAY[ARCADE_ARMOR_RED] = 3;
	// all normal weapons cost 1 gold
	for(int i=WEAP_NORMAL;i<WEAP_NORMAL+10;i++){
		PRICE_ARRAY[i]=1;
	}
	// all legendary weapons cost 10 gold
	for(int i=WEAP_LEGENDARY;i<WEAP_LEGENDARY+10;i++){
		PRICE_ARRAY[i]=10;
	}

    if ( !G_FileExists( "configs/server/gametypes/arc_map/" + mapName.get_string() + ".cfg" ) )
    {
        WaveController.FindSpawns("info_player_deathmatch"); // finds possible spawns
    }
    else
    {
        WaveController.LoadCustomSpawns();
    }

}

// Important: This function is called before any entity is spawned, and
// spawning entities from it is forbidden. If you want to make any entity
// spawning at initialization do it in GT_SpawnGametype, which is called
// right after the map entities spawning.

void GT_InitGametype()
{
    gametype.title = "Arcade Co-Op";
    gametype.version = "0.33";
    gametype.author = "Xanthus (with sounds by jihnsius)";

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
                 + "// This config will be executed each time the gametype is started\n"
                 + "\n\n// map rotation\n"
                 + "set g_maplist \"wdm1 wdm2 wdm3 wdm4 wdm5 wdm6 wdm7 wdm8 wdm9 wdm10 wdm11 wdm12 wdm13 wdm14 wdm15 wdm16 wdm17\" // list of maps in automatic rotation\n"
                 + "set g_maprotation \"0\"   // 0 = same map, 1 = in order, 2 = random\n"
                 + "\n// game settings\n"
                 + "set g_scorelimit \"0\"\n"
                 + "set g_timelimit \"0\"\n"
                 + "set g_warmup_timelimit \"2\"\n"
                 + "set g_match_extendedtime \"0\"\n"
                 + "set g_allow_falldamage \"0\"\n"
                 + "set g_allow_selfdamage \"1\"\n"
                 + "set g_allow_teamdamage \"0\"\n"
                 + "set g_inactivity_maxtime \"0\"\n"
                 + "set g_allow_stun \"0\"\n"
                 + "set g_teams_maxplayers \"0\"\n"
                 + "set g_teams_allow_uneven \"0\"\n"
                 + "set g_countdown_time \"5\"\n"
                 + "set g_maxtimeouts \"3\" // -1 = unlimited\n"
                 + "set g_challengers_queue \"0\"\n"
                 + "set arc_portal \"1\"\n"
                 + "set arc_mapsize \"1\"\n"
                 + "set arc_mission \"normal\"\n"
                 + "set arc_difficulty \"100\"\n"
				 + "set dm_allowPowerups \"1\"\n"
                 + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

    gametype.spawnableItemsMask = ( IT_WEAPON | IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH ); // IT_WEAPON | IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH
    if ( gametype.isInstagib )
        gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);

    gametype.respawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);
    gametype.dropableItemsMask = gametype.spawnableItemsMask;
    gametype.pickableItemsMask = gametype.spawnableItemsMask;

    gametype.isTeamBased = false;
    gametype.isRace = false;
    gametype.hasChallengersQueue = false;
    gametype.maxPlayersPerTeam = 0;

    gametype.ammoRespawn = 0;
    gametype.armorRespawn = 0;
    gametype.weaponRespawn = 0;
    gametype.healthRespawn = 0;
    gametype.powerupRespawn = 0;
    gametype.megahealthRespawn = 0;
    gametype.ultrahealthRespawn = 0;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = true;
    gametype.shootingDisabled = false;
    gametype.infiniteAmmo = false;
    gametype.canForceModels = true;
    gametype.canShowMinimap = true;
    gametype.teamOnlyMinimap = false;

	gametype.mmCompatible = false;

    gametype.spawnpointRadius = 256;

    if ( gametype.isInstagib )
        gametype.spawnpointRadius *= 2;

    // set spawnsystem type
	for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
		gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );

    // define the scoreboard layout
    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%a l1 %n 112 %s 52 %i 52 %i 52 %l 48 %p 18 %p 18" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "AVATAR Name Clan Score Gold Ping C R" );

    // precache images that can be used by the scoreboard
    prcYesIcon = G_ImageIndex( "gfx/hud/icons/vsay/yes" );
    prcShockIcon = G_ImageIndex( "gfx/hud/icons/powerup/quad" );
    prcShellIcon = G_ImageIndex( "gfx/hud/icons/powerup/warshell" );


    // add commands
    G_RegisterCommand( "drop" );
    G_RegisterCommand( "gametype" );
    G_RegisterCommand( "debug" );
    G_RegisterCommand( "addspawn" );
    G_RegisterCommand( "savespawncfg" );
    G_RegisterCommand( "classAction1" );
    G_RegisterCommand( "classAction2" );
    G_RegisterCommand( "gametypemenu" );
    G_RegisterCommand( "abilityshop1" );
    G_RegisterCommand( "abilityshop2" );
    G_RegisterCommand( "weapshop" );
	G_RegisterCommand( "armorshop" );
	G_RegisterCommand( "legendweapshop" );
    G_RegisterCommand( "upgradeshop" );
    G_RegisterCommand( "refundmenu" );
    G_RegisterCommand( "helpmenu" );
    G_RegisterCommand( "buy" );
    G_RegisterCommand( "refund" );
    G_RegisterCommand( "switchabilities" );

    G_RegisterCallvote("arc_portal", "0-3","integer", "Current: "+arc_portal.get_integer()+"\n-Frequency/timer of portal (0 being off, 3 being the fastest)\n" );
    G_RegisterCallvote("arc_mapsize", "<number>","integer", "Current: "+arc_mapsize.get_integer()+"\n-Size of map\n- 0:Tiny \n- 1:Small/Duel\n- 2:Medium/2v2\n- 3:Large/4v4\n");
    G_RegisterCallvote("arc_mission", "<text>", "string", "Current: "+arc_mission.get_string()+"\n-Name of the mission config file (without the arc_ prefix)\n ");
    G_RegisterCallvote("arc_difficulty", "<50-300>","integer", "Current: "+arc_difficulty.get_integer()+"\n-Percentage of normal difficulty. Affects damage and health of enemies\n");
	G_RegisterCallvote( "dm_allow_powerups", "1 or 0", "bool", "Enables or disables the spawning of powerups" );

    //WAVE_SMALL = [4,2,105,5]; // first number is wave array size, 2nd number is max number at 1 time

	// make assets pure
	G_ModelIndex("gfx/en/bat.tga",true);

    G_Print( "Gametype '" + gametype.title + "' initialized\n" );
}
