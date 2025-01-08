/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/
// Enemy for the enemy gametype

cARCPlayer[] gtPlayers( maxClients);

const int ABILITY_FLY = 11; // abilities in 10's
const int ABILITY_PUSH = 12;
const int ABILITY_SHIELD = 13;
const int ABILITY_DOUBLEJ = 14;
const int ABILITY_SMITH = 15;
const int ARCADE_ARMOR_GREEN = 21; // armor in the 20s
const int ARCADE_ARMOR_YELLOW = 22;
const int ARCADE_ARMOR_RED = 23;
const int WEAP_NORMAL = 30; // Normal weapons in the 30's. Use: WEAP_NORMAL+WEAP_ELECTROBOLT
const int UP_DASH = 41; // upgrades in the 40's
const int UP_REGEN = 42;
const int UP_RAGE = 43;
const int ITEM_TRANSLOCATOR = 51; //items in 50's
const int WEAP_LEGENDARY = 60; // Legendary weapons in the 60's. Use: WEAP_LEGENDARY+WEAP_ELECTROBOLT

const int GOLD_DMG_THRESH = 300; // get gold for every 300 dmg

class cARCPlayer
{
    Entity @indicator;

    int cliNum;
    int entNum; // the entNumber this corresponds with
    // scoreboard type stats
    float waveDamage; // temp damage holder
    float lastWaveDamage; // for calculating hitsounds for enemies
    float totalDamage;
    int wavePortals; // portals closed this wave
    int totalPortals;
    int waveBonus;
    int totalBonus;
    int kills;
    int bonus;

    int legendary; // keeps track of legendary weapons

    Vec3 lastLocation; // i need this so legendaries can be dropped at this location when you spectate

    // stats for upgrades
    int gold;
    int abilityOne;
    int abilityTwo;
    int upgrade;
    int item;
    int misc;

    uint nextCharge;
    int doubleJumps;
    uint lastHurt;
    float lastHealth;
    int goldDmg; // used to get gold (every GOLD_DMG_THRESH  amount of dmg)

    int maxHealth;
    int maxArmor;


    void Init()
    {
        waveDamage = 0;
        totalDamage = 0;
        wavePortals = 0;
        totalPortals = 0;
        waveBonus = 0;
        totalBonus = 0;
        kills = 0;
        bonus = 0;
        legendary = 0;

        gold = 0;
        abilityOne = 0;
        abilityTwo = 0;
        upgrade = 0;
        item = 0;
        misc = 0;

        nextCharge = 0;
        doubleJumps = 0;
        goldDmg = 0;
        lastHurt = 0;
        lastHealth = 0;

        maxHealth = 200; // not used for anything atm
        maxArmor = 200;

        if (@indicator != null)
        {
            indicator.freeEntity();
        }

        @this.indicator = @G_SpawnEntity("indicator");

        this.indicator.type = ET_SPRITE;
        indicator.modelindex = G_ImageIndex("gfx/misc/teammate_indicator.tga");
        indicator.frame = 25;
        indicator.svflags = uint(SVF_NOCLIENT);
        indicator.linkEntity();
    }

    cARCPlayer()
    {
    }

    ~cARCPlayer()
    {
    }

    void think()
    {
        if (G_GetEntity(entNum).isGhosting())
        {
            return;
        }
        // see if you were hurt
        if (G_GetEntity(entNum).health < lastHealth)
        {
            lastHurt = levelTime;
        }
        lastHealth = G_GetEntity(entNum).health;

        //reset double jumps when on ground
        int maxDoubleJumps = 0;
        if ( (abilityOne == ABILITY_DOUBLEJ) or (abilityTwo == ABILITY_DOUBLEJ) )
        {
            maxDoubleJumps = 1;
        }
        if ( (abilityOne == ABILITY_FLY) or (abilityTwo == ABILITY_FLY) )
        {
            maxDoubleJumps = 3;
        }

        if ( upgrade == UP_REGEN )
        {
            if ( (G_GetEntity(entNum).health<125) && (lastHurt < (levelTime-4000) ) ) // regen after 4 seconds
            {
                G_GetClient(cliNum).inventorySetCount(POWERUP_REGEN, 1);
            }
            else
            {
                G_GetClient(cliNum).inventorySetCount(POWERUP_REGEN, 0);
            }
        }

        if ( upgrade == UP_RAGE )
        {
            Vec3 horizontal_velocity(G_GetEntity(entNum).velocity.x,G_GetEntity(entNum).velocity.y,0);
            if ( (horizontal_velocity.length() > 700) && (G_GetClient(cliNum).inventoryCount(POWERUP_QUAD) < 3) )
            {
                G_GetClient(cliNum).inventorySetCount(POWERUP_QUAD, 3);
            }
            if ( (horizontal_velocity.length() > 800) && (G_GetClient(cliNum).inventoryCount(POWERUP_QUAD) < 5) )
            {
                G_GetClient(cliNum).inventorySetCount(POWERUP_QUAD, 5);
            }
            if ( (horizontal_velocity.length() > 1000) && (G_GetClient(cliNum).inventoryCount(POWERUP_QUAD) < 10) )
            {
                G_GetClient(cliNum).inventorySetCount(POWERUP_QUAD, 10);
            }
        }

        if (onGround())
        {
            doubleJumps = maxDoubleJumps;
        }
    }

	/* no longer used, only keep stats for single game
    void loadStats()
    {
        bool existing = false; // if player exists in cfg already
        String Players_String;

        if ( G_FileExists( "configs/server/gametypes/arcplayers/"+G_GetClient(cliNum).get_name()+".cfg" ) ) // load config as string, or make one
        {
            Players_String = G_LoadFile( "configs/server/gametypes/arcplayers/"+G_GetClient(cliNum).get_name()+".cfg" );

            this.gold = Players_String.getToken( 0 ).toInt();
            this.abilityOne = Players_String.getToken( 1 ).toInt();
            this.abilityTwo = Players_String.getToken( 2 ).toInt();
			this.kit = Players_String.getToken( 3 ).toInt();
            this.upgrade = Players_String.getToken( 4 ).toInt();
            //placeholder (items)
            //placeholder (misc.)

        }
        else // make new blank file
        {
            Players_String = "10\n 0\n 0\n 0\n 0\n 0\n 0\n";
            G_WriteFile( "configs/server/gametypes/arcplayers/"+G_GetClient(cliNum).get_name()+".cfg", Players_String );
        }

    }


    void saveStats()
    {
        // save stats (gold, ability, ability2, kit, upgrade, item, misc)
        String Players_String = ""+(gold+refundKit)+" \n"+abilityOne+" \n"+abilityTwo+" \n"+kit+" \n"+
            upgrade+" \n"+item+" \n"+misc+" \n";
        G_WriteFile( "configs/server/gametypes/arcplayers/"+G_GetClient(cliNum).get_name()+".cfg", Players_String );
    }
	*/

    void reset()
    {
        // reset stats
        waveDamage = 0;
        wavePortals = 0;
        waveBonus = 0;
        bonus = 0;
        kills = 0;
		gold = 3; // start with 3 gold
		goldDmg = 0;

        legendary = 0;

        nextCharge = 0;
    }

    void die()
    {
        if (gametype.dropableItemsMask != 0 )
        {
            this.dropLegendary();
        }

        nextCharge = 0;
    }

    void useAbility(int abilityNum)
    {
        int abilityCheck;// store based on whichever classaction you're using
        if (abilityNum == 1)
        {
            abilityCheck = abilityOne;
        }
        else // 2nd ability
        {
            abilityCheck = abilityTwo;
        }

        if (abilityCheck == ABILITY_DOUBLEJ)
        {
            //only do if you're not on the ground
            if (onGround() == true)
            {
                return;
            }
            if (doubleJumps > 0)
            {
                doubleJumps -= 1;
                // jump
                Vec3 dir(G_GetEntity(entNum).get_velocity().x,G_GetEntity(entNum).get_velocity().y,350);

                G_GetEntity(entNum).set_velocity(dir);

                int soundIndex = G_SoundIndex( "sounds/xan/bobot_wing_flap_0" + int( brandom( 1, 5 ) ) + "v.ogg", true );
                G_Sound(G_GetEntity(entNum), CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation
            }
            else
            {
                G_GetClient(cliNum).printMessage("^1Need to land before using this ability again\n");
            }
        }
        if (abilityCheck == ABILITY_PUSH)
        {
            if (this.nextCharge<=levelTime)
            {
                this.nextCharge = levelTime + 5001; // 5 seconds before full recharge. 5001 is used in the dmg check to stun enemies

                G_GetEntity(entNum).explosionEffect(250);
                G_GetEntity(entNum).splashDamage( G_GetEntity(entNum), 600, 25, 300, 0, MOD_EXPLOSIVE );
            }
            else
            {
                G_GetClient(cliNum).printMessage("^1Ability is still re-charging\n");
            }
        }
        if (abilityCheck == ABILITY_FLY)
        {
            //only do if you're not on the ground
            if (onGround() == true)
            {
                return;
            }
            if (doubleJumps > 0)
            {
                doubleJumps -= 1;
                // fly
                Vec3 dir(G_GetEntity(entNum).get_velocity().x,G_GetEntity(entNum).get_velocity().y,350);

                G_GetEntity(entNum).set_velocity(dir);

                int soundIndex = G_SoundIndex( "sounds/xan/bobot_wing_flap_0" + int( brandom( 1, 5 ) ) + "v.ogg", true );
                G_Sound(G_GetEntity(entNum), CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation
            }
            else
            {
                G_GetClient(cliNum).printMessage("^1Need to land before using this ability again\n");
            }
        }
        if (abilityCheck == ABILITY_SHIELD)
        {
            if (this.nextCharge<= levelTime)
            {
                int shieldTime = G_GetClient(cliNum).inventoryCount(POWERUP_SHELL) + 4; // give 4 more than you currently have

                this.nextCharge = levelTime + 10000; // 10 seconds before recharge

                G_GetClient(cliNum).inventorySetCount( POWERUP_SHELL, shieldTime);

                int soundIndex = G_SoundIndex( "sounds/items/shell_pickup.ogg", true );
                G_Sound(G_GetEntity(entNum), CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation
            }
            else
            {
                G_GetClient(cliNum).printMessage("^1Ability is still re-charging\n");
            }
        }

        if (abilityCheck == ABILITY_SMITH)
        {
            if (G_GetClient(cliNum).armor >= 30)
            {
                G_GetClient(cliNum).armor -= 30;

                int choose;
                if (G_GetClient(cliNum).weapon == WEAP_GUNBLADE) // make random weapon with gunblade
                {
                    choose = int(brandom(WEAP_MACHINEGUN,WEAP_ELECTROBOLT+0.999f));
                }
                else // otherwise, smith current weapon
                {
                    choose = G_GetClient(cliNum).weapon;
                }

                Entity @dropped = G_GetEntity(entNum).dropItem(choose);
                dropped.count = 150; // give it max ammo
            }
            else
            {
                G_GetClient(cliNum).printMessage("^1Need 30 Armor to Smith a weapon\n");
            }
        }

        /* custom dash
        Vec3 newDash;
        Vec3 wat,watt;
        G_GetEntity(entNum).get_angles().angleVectors(newDash, wat, watt);
        newDash.z = 0;

        newDash.normalize();
        newDash *= 750;
        newDash.z = 200;
        G_GetEntity(entNum).set_velocity( newDash );
        */
    }

    void hurt()
    {
        lastHurt = levelTime;
    }

    void dmg(Entity @self, Entity @target, int dmg)
    {
        // if hurting enemy
        if (target.team != self.team)
        {
            if( (this.abilityOne == ABILITY_PUSH) && (this.nextCharge == levelTime + 5001) ) //if you used explosive push
            {
                target.nextThink = levelTime + 500; // stun for half second
            }
        }
    }

    void kill(Vec3 targetOrigin)
    {

    }

    void dropLegendary()
    {
        if (legendary != 0)
        {
            Entity @legItem;
            @legItem = G_GetEntity(entNum).dropItem(legendary);
            Legendary_Spawn(@legItem, legendary);

            legItem.count = 150; // give it ammo

            legendary = 0;
        }
    }

    bool onGround()
    {
        Trace ln;
        Vec3 end, start, mins( -16, -16, 0 ), maxs( 16, 16, 0 );

        start = end = G_GetEntity(entNum).get_origin();   // getting origin vectors
        end.z -= 32;   // sets z endpoint

        if ( ln.doTrace( start, mins, maxs, end, entNum, MASK_SOLID ) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }

}

void InitARCPlayers()
{
    for (int i = 0; i< maxClients; i++)
    {
        gtPlayers[i].Init();
        gtPlayers[i].cliNum = G_GetClient(i).get_playerNum();
        gtPlayers[i].entNum = G_GetClient(i).getEnt().get_entNum();
    }
}

void ResetARCPlayers() // reset temp stats at start of the game
{
    for (int i = 0; i< maxClients; i++)
    {
        cARCPlayer @player= @gtPlayers[i];

        player.reset();
    }
}


void PlayerThink()
{
    for (int i = 0; i< maxClients; i++)
    {
        gtPlayers[i].think();
        gtPlayers[i].lastLocation = G_GetEntity(gtPlayers[i].entNum).origin;

        // play hitsounds
        Client @client = @G_GetClient(i);
        if (@G_GetClient == null)
        {
            continue;
        }

        int dmg = int(gtPlayers[i].waveDamage - gtPlayers[i].lastWaveDamage);

		// see if you've done enough dmg to get gold
		if(gtPlayers[i].goldDmg>=GOLD_DMG_THRESH){
			gtPlayers[i].goldDmg-=GOLD_DMG_THRESH;
			gtPlayers[i].gold+=1;
		}

        int painIndex = 3; // less than 10 dmg
        if ( dmg > 10) { painIndex = 2;}
        if ( dmg > 30) { painIndex = 1;}
        if ( dmg >= 70) { painIndex = 0;}
        if (dmg > 0)
        {
            int soundIndex = G_SoundIndex( "sounds/misc/hit_" + painIndex + ".wav", true );
            G_LocalSound( client, CHAN_AUTO, soundIndex );
        }

        // reset damage
        gtPlayers[i].lastWaveDamage = gtPlayers[i].waveDamage;
    }
}

// possibly use later for buffs / special stuff
void TeamIndicatorFollow()
{
    /*
    for (int i = 0; i< maxClients; i++)
    {
        Client @client = G_GetClient(i);
        if (!client.getEnt().isGhosting())
        {
            Vec3 newOrigin;
            newOrigin = client.getEnt().origin;
            newOrigin.z += 40;
            gtPlayers[i].indicator.origin = newOrigin;
            gtPlayers[i].indicator.svflags = SVF_ONLYTEAM;
        }
        else
        {
            gtPlayers[i].indicator.svflags = SVF_NOCLIENT;
        }
    }
    */
}

void MessagePlayers(String &message)
{
    int i;

    for (i=0; i<maxClients; i++)
    {
        if (@G_GetClient(i) != null)
        {
            G_PrintMsg( G_GetClient(i).getEnt(), "^5-[^7"+message+"^5]-\n");
        }
    }
}

void ShowARCStats()
{
    int i;

    for (i=0; i<maxClients; i++)
    {
        if (@G_GetClient(i) != null)
        {
            // cycle through players, show stats for those on team alpha
            G_PrintMsg( G_GetClient(i).getEnt(), "^5-[^7 Name: [Total Damage] (Portals closed) ^5]-\n");
            int j;
            for (j=0; j<maxClients; j++)
            {
                Client @client = @G_GetClient(j);
                cARCPlayer player = gtPlayers[j];

                if (client.getEnt().team == TEAM_ALPHA)
                {
                    G_PrintMsg( G_GetClient(i).getEnt(), "^5-[^7 "+client.get_name()+"^7: ["+int(player.totalDamage)+"] ("+player.totalPortals+")^5]-\n");
                }
            }
        }
    }
}

