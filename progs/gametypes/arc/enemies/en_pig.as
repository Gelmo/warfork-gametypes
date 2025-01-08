/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

void pig_think( Entity @self)
{
    cEnemy @eC; // enemyClass
    @eC = @gtEnemies[self.count];
    self.nextThink = levelTime+10; //keep thinking for walking

    //G_Print("^1Tell pig to think!\n"); // debug

    if (eC.active != true)
    {
        return;
    }

    if ( (eC.phase == 0) && (eC.nextPhaseThink < levelTime) ) // scan and walk towards player
    {
        eC.move.GroundCheck();
        Entity @target;

        eC.nextPhaseThink = levelTime+200;

        @target = @eC.action.scanNearestPlayer(eC.range, true);

        // if you see a player, chase him/attack, and do so for the next few secs
        // move towards closest
        if (@target != null)
        {
            eC.lastSeenTime = levelTime;
            @eC.targetEnt = @target;
            eC.lastSeenVec = target.origin;

            // rocket jump if he's much higher
            if ( (eC.move.onGround ) && (target.origin.z > self.origin.z +150) && (self.health > 10) && (eC.RJTime < levelTime) )
            {
                eC.action.RocketJump(150);
                eC.RJTime = levelTime+5000;
                eC.nextPhaseThink = levelTime+1000;
                //self.health -= 10;
            }

            // if you're not too close, move towards target
            if ( self.origin.distance(target.origin) > 300 )
            {
                eC.move.walkTowards(target.origin, eC.speed, eC.jumpSpeed);
            }
            else
            {
                eC.move.stop();
            }

            //shooting
            if (eC.reloadTime < levelTime)
            {
                switch (eC.type)
                {
                    case EN_PIG_GL: eC.action.Shoot(WEAP_GRENADELAUNCHER,@eC.enemyEnt,@target,800,eC.damage,200,1); break;
                    case EN_PIG_RL: eC.action.Shoot(WEAP_ROCKETLAUNCHER,@eC.enemyEnt,@target,600,eC.damage,200,1); break;
                    case EN_PIG_PG: eC.action.Shoot(WEAP_PLASMAGUN,@eC.enemyEnt,@target,1000,eC.damage,50,1); break;
                    default: break;
                }
                eC.reloadTime = levelTime + eC.reloadDelay;
                if (eC.reloadDelay < 200) // Reset think if you want to shoot faster than 200 ms
                {
                    eC.nextPhaseThink = levelTime+eC.reloadDelay;
                }
            }
        }
        else if ( (@eC.targetEnt != null) && (eC.lastSeenTime + 3000 > levelTime) ) // chase the player for the next two seconds still
        {
            // walk towards the last place you saw them
            eC.move.walkTowards(eC.lastSeenVec, eC.speed, eC.jumpSpeed);

            // and try to jump towards them
            if ( eC.move.onGround )
            {
                eC.move.jumpTowards(eC.lastSeenVec, eC.jumpSpeed);

                // rocket jump if he's much higher
                if ( (eC.lastSeenVec.z > self.origin.z +150) && (self.health > 10) && (eC.RJTime < levelTime) )
                {
                    eC.action.RocketJump(150);
                    eC.RJTime = levelTime + 5000;
                    self.health -= 10;
                }
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

void pig_die( Entity @self , Entity @inflicter, Entity @attacker )
{
    //G_Print("^6DEAD\n"); //debug
    self.explosionEffect(50);

    gtEnemies[self.count].die(@attacker);
}

int pig_spawn(Vec3 location)
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

    @eC.enemyEnt = @G_SpawnEntity("pig");
    @eC.enemyEnt.think = pig_think;
    @eC.enemyEnt.die = pig_die;
    eC.enemyEnt.moveType = MOVETYPE_TOSSSLIDE;
    eC.enemyEnt.solid = SOLID_YES;
    eC.enemyEnt.clipMask = MASK_PLAYERSOLID;
    eC.enemyEnt.setSize(tmins,tmaxs);
    eC.enemyEnt.type = ET_SPRITE;
    eC.enemyEnt.effects = EF_QUAD;
    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/pig.tga");
    eC.enemyEnt.frame = 40;
    eC.enemyEnt.takeDamage = DAMAGE_YES;
    eC.enemyEnt.health = 150;
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
    eC.speed = 200;
    eC.jumpSpeed = 100;
    eC.reloadDelay = 800;

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

