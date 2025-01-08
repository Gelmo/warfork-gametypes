/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

// Enemy for the enemy gametype

const int MAX_ENEMIES = 64;
cEnemy [] gtEnemies(MAX_ENEMIES);
cLoot Loot;

const int NO_AVAILABLE_ENEMIES = -1;

// define enemy pools / types
const int POOL_EASY = 101;
const int POOL_MED = 102;
const int POOL_HARD = 103;

const int ITEM_IGNORE_MAX = 524288; // 0x00080000 . used for hp bubbles/ megahealth to go above 100

const int EN_BAT = 0;
const int EN_WALKER = 1;
const int EN_PIG = 2;
const int EN_PIG_GL = 3;
const int EN_PIG_RL = 4;
const int EN_PIG_PG = 5;
const int EN_SNIPER = 6;
const int EN_CHEST = 7;
const int EN_SHIELD = 8;
const int EN_WIZARD = 9;
const int EN_WALKER_QUICK = 10;

class cLoot
{
    int weap;
    int shard;
    int bubble; // 5 hp bubbles
    int mega;
    int ga;
    int shell;
    int quad;
    int legend; // legendary
    int[] lastLegendaries;
    int none;

    void Reset()
    {
        weap = 40;
        shard = 16;
        bubble = 16;
        ga = 4;
        mega = 2;
        shell = -15;
        quad = -10;
        legend = -20;
        none = 33;

        lastLegendaries = CLEAR_ARRAY;
    }

    void SpawnRandom(Entity @player, Vec3 source)
    {
        int choose_legend = 1337; // set drop to this when you choose a legendary
        int drop = 0;
        int rand = int(brandom(0, weap+shard+bubble+mega+ga+shell+quad+legend+none));

        if ( (rand>0) && (rand<weap) )
        {
            drop = int(brandom(WEAP_MACHINEGUN,WEAP_ELECTROBOLT+0.999f));
        } else{ rand -= weap; } // moving what you're checking over

        if ( (drop== 0) and (rand < shard) ) // if you still haven't chosen something, and less than chance
        {
            drop = ARMOR_SHARD;
        } else{ rand -= shard;}

        if ( (drop== 0) and (rand < bubble) )
        {
            drop = HEALTH_SMALL;
        } else{ rand -= bubble; }

        if ( (drop== 0) and (rand < mega) )
        {
            mega = 2;
            drop = HEALTH_MEGA;
        } else{ rand -= mega; }

        if ( (drop== 0) and (rand < ga) )
        {
            ga = 4;
            drop = ARMOR_GA;
        } else{ rand -= ga; }

        if ( (drop== 0) and (rand < shell) )
        {
            shell = -15;
            drop = POWERUP_SHELL;
        } else{ rand -= shell; }

        if ( (drop== 0) and (rand < quad) )
        {
            quad = -10;
            drop = POWERUP_QUAD;
        } else{ rand -= quad; }
        if ( (drop== 0) and (rand < legend) )
        {
            int randomLegend = LegendaryPick( gtPlayers[player.client.get_playerNum()].legendary);
            Entity @legItem = @DropItem(@player, source, randomLegend);
            Legendary_Spawn(@legItem, randomLegend );

            legend = -15;
            drop = choose_legend;
        } else{ rand -= legend; }

        // increase rare powerups if they didn't drop
        if (drop != ARMOR_GA) {ga+=1;}
        if (drop != HEALTH_MEGA) {mega+=1;}
        if (drop != POWERUP_SHELL) {shell+=1;}
        if (drop != POWERUP_QUAD) {quad+=1;}
        if (drop != choose_legend) {legend+=1;} else {drop = 0;} // legendaries are more rare, and are manually dropped above


        if (drop != 0)
        {
            if ( (drop == ARMOR_SHARD) || (drop == HEALTH_SMALL) )
            {
				// drop extra shards/bubbles
				// ignore max for health / shards
                DropItem(@player, source, drop).spawnFlags |= ITEM_IGNORE_MAX;
                DropItem(@player, source, drop).spawnFlags |= ITEM_IGNORE_MAX;
            }

            DropItem(@player, source, drop).spawnFlags |= ITEM_IGNORE_MAX;
        }
    }

    int LegendaryPick(int playersLegendary)
    {
        int chosen;
        bool picked = false;
        while (picked == false)
        {
            // never give the same legendary a player has
            chosen = playersLegendary;
            while (chosen == playersLegendary)
            {
                chosen = int(brandom(WEAP_MACHINEGUN,WEAP_ELECTROBOLT+0.999f));
            }

            // see if it's in the array
            bool inArray = false;
            uint i = 0;
            while ( i<lastLegendaries.length() )
            {
                if (lastLegendaries[i] == chosen)
                {
                    inArray = true;
                }

                i++;
            }

            // if it's not, pick it and add it to the array!
            if (inArray == false)
            {
                lastLegendaries.insertLast(chosen);
                // if the array has more than 5 entries, remove one
                if (lastLegendaries.length() > 5)
                {
                    lastLegendaries.removeAt(0);
                }

                picked = true;
            }
        }

        return chosen;
    }

    Entity @DropItem(Entity @player, Vec3 source, int type)
    {
        if (@player!=null)
        {
            Entity @dropped;
            int neg = int(brandom(0,1.999f)); // make the number negative sometimes
            if(neg == 1){
                neg = -1;
            }
            else {
                neg = 1;
            }
            int negg = int(brandom(0,1.999f)); // make the number negative sometimes
            if(negg == 1){
                negg = -1;
            }
            else {
                negg = 1;
            }
            int xRand = int(brandom(20,100)*neg);
            int yRand = int(brandom(20,100)*negg);

            // save quaed / shell to restore after dropping
            int quad = player.client.inventoryCount( POWERUP_QUAD);
            int shell = player.client.inventoryCount( POWERUP_SHELL);

            //if type is a weapon, give it some ammo
            @dropped = player.dropItem( type );
            if (type == POWERUP_QUAD)
            {
                dropped.count = 15;
            }
            if (type == POWERUP_SHELL)
            {
                dropped.count = 20;
            }
            if ( (type >= WEAP_MACHINEGUN) && (type <= WEAP_ELECTROBOLT) )
            {
                dropped.count = 150;
            }
            if ( (type == HEALTH_SMALL) or (type == HEALTH_MEGA) )
            {
                dropped.style = 3;
            }

            dropped.origin = Vec3(source.x,source.y,source.z+4);
            dropped.velocity = Vec3(xRand,yRand,250);

            // restore quad/shell
            player.client.inventorySetCount( POWERUP_QUAD, quad );
            player.client.inventorySetCount( POWERUP_SHELL, shell );

            return @dropped;
        }
        return null;
    }

    cLoot()
    {
        this.Reset();
    }

    ~cLoot()
    {
    }
}


class cEnemy
{
    Entity @enemyEnt;
    IMovement move;
    IActions action;

    Entity @targetEnt;

    bool active;
    bool attacking;
    int type;
    int speed;
    int damage;
    int jumpSpeed;
    int phase;
    uint RJTime;
    uint reloadTime;
    int reloadDelay;
    uint nextPhaseThink;
    uint lastSeenTime;
    Vec3 lastSeenVec;
    int range;
    Vec3 mins;
    Vec3 maxs; //hitbox size

    void Init()
    {
        active = false;
        attacking = false;
        type = 0;
        speed = 0;
        damage = 0;
        jumpSpeed = 0;
        phase = 0;
        reloadTime = 0;
        RJTime = 0;
        lastSeenTime = 0;
        @targetEnt = null;
        @enemyEnt = null;
    }

    void Set()
    {
        this.move.Init(@this.enemyEnt);
        this.action.Init(@this.enemyEnt);
    }

    cEnemy()
    {
        this.Init();
    }

    ~cEnemy()
    {
    }

    void enemy_respawn()
    {
        this.active = false;
        this.enemyEnt.freeEntity();

        // insert at the beginning of mission wave if during play
        if ( match.getState() == MATCH_STATE_PLAYTIME)
        {
            WaveController.RespawnEnemyType(this.type);
        }
    }

    void die(Entity @attacker)
    {
        int soundIndex = G_SoundIndex( "sounds/xan/enemy_kill01.ogg",true );
        G_Sound(this.enemyEnt, CHAN_BODY, soundIndex, 0.5f);

        // drop Riotgun ammo for gunblade kill, hp for low player
        if (@attacker.client != null)
        {
            int item = 0;
            if (attacker.weapon == WEAP_GUNBLADE) // if you kill with GB, get random weapon todo: EB doesn't seem to spawn anymore
            {
                item =  int(brandom(WEAP_MACHINEGUN,WEAP_ELECTROBOLT+0.999f));
                Loot.DropItem( @attacker, enemyEnt.origin, item);
            }
            else
            {
                Loot.SpawnRandom(@attacker, enemyEnt.origin);
            }

            Legendary_Kill(@attacker,enemyEnt.origin);
            gtPlayers[attacker.get_playerNum()].kill(enemyEnt.origin);
        }


        this.enemyEnt.freeEntity();
        @this.enemyEnt = null;

        // special stuff to arcade
        if (this.type == EN_CHEST)
        {
            WaveController.chestSpawned -= 1;
        }
        else
        {
            WaveController.enemyCount -= 1; // curently alive
            WaveController.enemyCountRemaining -= 1; // how many kills are left in the wave
        }
        if (WaveController.chestSpawn > 0)
        {
            WaveController.chestSpawn -= 1; // 1 closer to spawning the chest
        }

        this.Init();
    }

    void Roam(bool fly)
    {
        if (!fly && !this.move.onGround && this.move.canJump) // if you're a walker in air and you didn't jump (walked off ledge)
        {
			// reverse hop to stay on the platform you walked off
            Vec3 reverseHop(this.enemyEnt.velocity.x*-1,this.enemyEnt.velocity.y*-1,300);
            this.enemyEnt.velocity = reverseHop;
            this.move.walkingVel = reverseHop;
            this.move.canJump = false;
        }
        if (this.speedTest() == false) // change directions if you hit something
        {
            if (!fly)
            {
                this.move.walkRoam(this.speed, this.jumpSpeed);
            }
            else
            {
                this.move.flyRoam(this.speed);
            }
        }
    }

    bool speedTest() // see if you're moving around the speed that you should (see if you run into wall)
    {
        float calcSpeed,xspeed,yspeed,zspeed;
        xspeed = this.enemyEnt.velocity.x;
        yspeed = this.enemyEnt.velocity.y;
        zspeed = this.enemyEnt.velocity.y;
        calcSpeed = sqrt((xspeed*xspeed)+(yspeed*yspeed)+(zspeed*zspeed));

        if ( calcSpeed < (this.speed*0.9f) )
        {
            return false;
        }

        return true;
    }
}




///*****************************************************************
/// BASIC ENEMY CONTROL FUNCTIONS (unstuck, remove all, find available, find nearest player, hurt)
///*****************************************************************

void enemy_remove_all(bool explode)
{
    int i = 0;

    while ( i < MAX_ENEMIES )
    {
        if (@gtEnemies[i].enemyEnt != null)
        {
            if (explode == true)
            {
                gtEnemies[i].enemyEnt.explosionEffect(75);
            }
            gtEnemies[i].enemyEnt.freeEntity();
            gtEnemies[i].Init();
        }

        i++;
    }
}

int available_enemy()
{
    // choose an available enemy, then use it
    int i = 0;

    while ( (i < MAX_ENEMIES) && (gtEnemies[i].active == true) )
    {
        //G_Print("^1Enemy #"+i+" is being used!\n"); // debug

        i++;
    }

    if (i == MAX_ENEMIES) // if reached max, all enemies are already spawned!
    {
        //G_Print("^1No more enemies! "+i+"\n");
        return NO_AVAILABLE_ENEMIES;
    }
    else // return cEnemy Value
    {
        //G_Print("^2Spawn Enemy #"+i+"\n"); //debug

        return i;
    }
}

// this is in case enemies glitch through walls or just went somewhere hard to see.
/*
if ( (eC.lastSeenTime+15000) < levelTime )
{
    eC.active = false;
    eC.enemyEnt.freeEntity();

    WaveController.RespawnEnemyType(eC.type);

    WaveController.enemyCount -=1;
    WaveController.enemyCountRemaining +=1;
}*/
