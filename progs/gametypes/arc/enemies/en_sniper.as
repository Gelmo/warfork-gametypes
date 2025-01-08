/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

void sniper_think( Entity @self)
{
    cEnemy @eC; // enemyClass
    @eC = @gtEnemies[self.count];
    self.nextThink = levelTime+10; //keep thinking for walking

    //G_Print("^1Tell pig to think!\n"); // debug

    if (eC.active != true)
    {
        return;
    }

    if ( eC.nextPhaseThink < levelTime) // scan and walk towards player
    {
        eC.move.GroundCheck();
        Entity @target;

        eC.nextPhaseThink = levelTime+200;
        eC.speed = 350; //set speed: will get altered if shooting

        @target = @eC.action.scanNearestPlayer(eC.range, true);

        // if you see a player, chase him/attack, and do so for the next few secs
        // move towards closest
        if (@target != null)
        {
            eC.lastSeenTime = levelTime;
            @eC.targetEnt = @target;
            eC.lastSeenVec = target.origin;

            if (eC.phase == 1)// if you're aiming, take aim and stop
            {
                eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/wheelbot_aim.tga");
                eC.speed = 0;
            }

            // walk/jump away from target if not aiming (reloading)
            if ( eC.move.onGround && (eC.phase != 1) )
            {
                eC.move.jumpTowards(eC.enemyEnt.origin,200);
            }

            eC.move.walkTowards(target.origin, eC.speed*-1, eC.jumpSpeed);

            //shooting
            if (eC.reloadTime < levelTime)
            {
                if (eC.phase == 1) // ready to shoot
                {
                    eC.action.Shoot(WEAP_ELECTROBOLT,@eC.enemyEnt,@target,800,eC.damage,200,1);
                    eC.phase = 0;
                    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/wheelbot_idle.tga");

                    eC.reloadTime = int(levelTime + (eC.reloadDelay*0.5f)); // short delay after shooting. (reload Delay is charging before shooting, not reloading after)

                    //pew pew
                    int soundIndex = G_SoundIndex( "sounds/weapons/electrobolt_strong.ogg" ,true);
                    G_Sound(self, CHAN_MUZZLEFLASH, soundIndex, 0.5f); // todo: fix attenuation
                }
                else
                {
                    eC.phase = 1;// make ready to shoot when you next think

                    eC.reloadTime = levelTime + eC.reloadDelay; // delay before actual shot

                    //charging
                    int soundIndex = G_SoundIndex( "sounds/weapons/laser_weak_hum.ogg" ,true);
                    G_Sound(self, CHAN_MUZZLEFLASH, soundIndex, 0.5f); // todo: fix attenuation
                }

                if (eC.reloadDelay < 200) // Reset think if you want to shoot faster than 200 ms
                {
                    eC.nextPhaseThink = levelTime+eC.reloadDelay;
                }
            }
        }
        else if ( (@eC.targetEnt != null) && (eC.lastSeenTime + 3000 > levelTime) ) // chase the player for the next two seconds still
        {
            // walk towards
            eC.phase = 0; // stop shooting
            eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/wheelbot_idle.tga");

            eC.move.walkTowards(eC.lastSeenVec, eC.speed, eC.jumpSpeed);

            // and try to jump towards them
            if ( eC.move.onGround )
            {
                eC.move.jumpTowards(eC.lastSeenVec, eC.jumpSpeed);
            }
        }
        else if ( (eC.lastSeenTime + 3000) < levelTime ) // after 3 seconds, roam
        {
            eC.Roam(false);
        }

        eC.move.walking(); // keeps velocity at walkVel
        eC.move.unstuck();

        // play skitter sound on ground
        if ( eC.move.onGround )
        {
            int soundIndex = G_SoundIndex( "sounds/xan/spider_skitter_0" + int( brandom( 1, 4 ) ) + ".ogg" ,true);
            G_Sound(self, CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation
        }
    }

}

void sniper_die( Entity @self , Entity @inflicter, Entity @attacker )
{
    //G_Print("^6DEAD\n"); //debug
    self.explosionEffect(50);

    gtEnemies[self.count].die(@attacker);
}

int sniper_spawn(Vec3 location)
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
    //G_Print("^3Spawn PIG #"+enemyIndex+" "+"\n"); // debug

    // make temporary vec3 for the hitbox because i don't know how to
    Vec3 tmins(-26,-26,-38);
    Vec3 tmaxs(26,26,38);

    @eC.enemyEnt = @G_SpawnEntity("sniper");
    @eC.enemyEnt.think = sniper_think;
    @eC.enemyEnt.die = sniper_die;
    eC.enemyEnt.moveType = MOVETYPE_TOSSSLIDE;
    eC.enemyEnt.solid = SOLID_YES;
    eC.enemyEnt.clipMask = MASK_PLAYERSOLID;
    eC.enemyEnt.setSize(tmins,tmaxs);
    eC.enemyEnt.type = ET_SPRITE;
    eC.enemyEnt.effects = EF_QUAD;
    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/wheelbot_idle.tga");
    eC.enemyEnt.frame = 40;
    eC.enemyEnt.takeDamage = DAMAGE_YES;
    eC.enemyEnt.health = 50;
    eC.enemyEnt.svflags = uint(SVF_BROADCAST);
    eC.enemyEnt.mass = 200;
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

    location.z += 32; // move up due to hitbox
    eC.enemyEnt.origin = location;
    eC.enemyEnt.nextThink = levelTime;
    eC.nextPhaseThink = levelTime+500;
    eC.lastSeenTime = levelTime;
    // TYPE is set after spawning pig, you have to give it a weapon after
    // Damage also set after because it depends
    eC.active = true;
    eC.range = 99999;
    eC.speed = 350;
    eC.jumpSpeed = 100;
    eC.reloadDelay = 1500;
    eC.damage = 30;

    eC.Set(); // sets up this entity with IMovement and IAction

    // if it spawns inside a solid, don't spawn it and return false
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

