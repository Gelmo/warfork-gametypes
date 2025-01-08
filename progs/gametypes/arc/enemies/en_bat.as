/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

void bat_think( Entity @self)
{
    cEnemy @eC; // enemyClass
    @eC = @gtEnemies[self.count];
    self.nextThink = levelTime+200;

    //G_Print("^1Tell bat to think!\n"); // debug

    if (eC.active != true)
    {
        return;
    }

    Entity @target;

    if ( (eC.phase == 0) && (eC.nextPhaseThink < levelTime) )
    {
        eC.move.GroundCheck();

        @target = @eC.action.scanNearestPlayer(eC.range, true);

        // if you see a player, chase him/attack. otherwise roam
        // move towards closest
        if (@target != null)
        {
            eC.lastSeenTime = levelTime;
            eC.move.flyTowards(target.origin, eC.speed);
            if (eC.enemyEnt.origin.distance(target.origin) < 100)
            {
                target.sustainDamage( @self, @self, self.origin, eC.damage, 0, 0, MOD_HIT );
                //Vec3 stop(0,0,0);
                //self.velocity = stop;
            }

        }
        else if ( (eC.lastSeenTime + 3000) < levelTime) // roam
        {
            eC.Roam(true);
            eC.nextPhaseThink = levelTime + 1000;
        }

        eC.move.unstuck();

        // play wing sound
        int soundIndex = G_SoundIndex( "sounds/xan/bobot_wing_flap_0" + int( brandom( 1, 5 ) ) + "v.ogg", true );
        G_Sound(self, CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation

        eC.nextPhaseThink = levelTime+200;
    }
}


void bat_die( Entity @self , Entity @inflicter, Entity @attacker )
{
    //G_Print("^6DEAD\n"); //debug
    self.explosionEffect(50);

    gtEnemies[self.count].die(@attacker);
}

int bat_spawn(Vec3 location)
{
    int enemyIndex = available_enemy();
    cEnemy @eC;

    if ( enemyIndex != NO_AVAILABLE_ENEMIES)
    {
        @eC = @gtEnemies[enemyIndex];
    }
    else
    {
        return NO_AVAILABLE_ENEMIES;
    }

    // actually spawn the enemy
    //G_Print("^3Spawn Bat #"+enemyIndex+" "+"\n"); // debug

    // make temporary vec3 for the hitbox because i don't know how to
    Vec3 tmins(-32,-32,-16);
    Vec3 tmaxs(32,32,16);

    @eC.enemyEnt = @G_SpawnEntity("bat");
    @eC.enemyEnt.think = bat_think;
    @eC.enemyEnt.die = bat_die;
	eC.enemyEnt.team = TEAM_PLAYERS;
    eC.enemyEnt.moveType = MOVETYPE_FLY;
    eC.enemyEnt.solid = SOLID_YES;
    eC.enemyEnt.clipMask = MASK_PLAYERSOLID;
    eC.enemyEnt.setSize(tmins,tmaxs);
    eC.enemyEnt.type = ET_SPRITE;
    eC.enemyEnt.effects = EF_ROTATE_AND_BOB;
    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/bat.tga");
    eC.enemyEnt.frame = 40;
    eC.enemyEnt.takeDamage = DAMAGE_YES;
    eC.enemyEnt.health = 40;
    eC.enemyEnt.svflags = uint(SVF_BROADCAST);
    eC.enemyEnt.linkEntity();

    // let it know where it's at in the array, set the entity's count to it's index in the array
    int index = -1;
    for ( int i = 0; i < MAX_ENEMIES; i++ )
    {
        if ( @gtEnemies[i] == @eC )
        {
            index = i;
            break;
        }
    }
    eC.enemyEnt.count = index;


    eC.enemyEnt.origin = location;
    eC.enemyEnt.nextThink = levelTime;
    eC.lastSeenTime = levelTime;
    eC.type = EN_BAT;
    eC.active = true;
    eC.range = 99999;
    eC.speed = 400;
    eC.damage = 5;
    eC.phase = 0;
    eC.nextPhaseThink = levelTime + 500;

    eC.Set(); // sets up this entity with IMovement and IAction

    // if it spawns inside a solid, remove it from enemyCount and add it back to the mission
    if ( eC.move.unstuck() )
    {
        //G_Print("^1Spawned inside solid, try again!\n"); //debug

        eC.enemyEnt.freeEntity();
        eC.active = false;

        return NO_AVAILABLE_ENEMIES;
    }

    // see if it's too close to a player
    Entity @nearestPlayer;

    @nearestPlayer = eC.action.scanNearestPlayer(300, true);
    if (@nearestPlayer != null)
    {
        eC.enemyEnt.freeEntity();
        eC.active = false;
        return NO_AVAILABLE_ENEMIES;
    }

    return enemyIndex;
}


