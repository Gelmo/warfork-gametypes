/*
Arcade Gametype for Warsow / Warfork
Xanthus 2019
*/

void shield_think( Entity @self)
{
    cEnemy @eC; // enemyClass
    @eC = @gtEnemies[self.count];
    self.nextThink = levelTime+10; //keep thinking for walking

    //G_Print("^1Tell shield to think!\n"); // debug

    if (eC.active != true)
    {
        return;
    }

    eC.move.walking(); // keeps velocity at walkVel

    if ( (eC.phase == 0) && (eC.nextPhaseThink < levelTime) ) // scan and walk towards player
    {
        eC.move.GroundCheck();

        Entity @target;

        @target = @eC.action.scanNearestPlayer(eC.range, true);

        // if you see a player, chase him/attack, and do so for the next few secs
        // move towards closest
        if (@target != null)
        {
            eC.lastSeenTime = levelTime;
            @eC.targetEnt = @target;
            eC.move.walkTowards(target.origin, eC.speed, eC.jumpSpeed);

            if (eC.enemyEnt.origin.distance(target.origin) < 100)
            {
                target.sustainDamage( @self, @self, self.origin, eC.damage, 0, 0, MOD_HIT );
            }
        }
        else if ( (@eC.targetEnt != null) && (eC.lastSeenTime + 3000 > levelTime) ) // chase the player for the next two seconds still
        {
            // don't need to change speed, keep going in the last direction you saw player. Just jump
            if ( eC.move.onGround )
            {
                eC.move.jumpTowards(eC.targetEnt.origin, eC.jumpSpeed);
            }
        }
        else if ( (eC.lastSeenTime + 3000) < levelTime ) // after 3 seconds, roam
        {
            eC.Roam(false);
        }


        eC.move.unstuck();

        eC.nextPhaseThink = levelTime+200;

        // play skitter sound on ground
        if ( eC.move.onGround )
        {
            int soundIndex = G_SoundIndex( "sounds/xan/spider_skitter_0" + int( brandom( 1, 4 ) ) + ".ogg" ,true);
            G_Sound(self, CHAN_BODY, soundIndex, 0.5f); // todo: fix attenuation
        }
    }

}

void shield_pain( Entity @self, Entity @other, float kick, float damage )
{
    cEnemy @eC = gtEnemies[self.count];

    if (@other.client != null)
    {
        switch (other.weapon)
        {
            case WEAP_ROCKETLAUNCHER: eC.action.Shoot(WEAP_ROCKETLAUNCHER,@eC.enemyEnt,@other,600,30,200,1); break;
            case WEAP_PLASMAGUN: eC.action.Shoot(WEAP_PLASMAGUN,@eC.enemyEnt,@other,1000,10,50,1); break;
            case WEAP_GRENADELAUNCHER: eC.action.Shoot(WEAP_GRENADELAUNCHER,@eC.enemyEnt,@other,600,40,200,1); break;
            case WEAP_GUNBLADE: eC.action.Shoot(WEAP_GUNBLADE,@eC.enemyEnt,@other,1300,int(damage*0.5f),int((damage/65.0f)*100.0f),1); break;
            default: break;
        }
    }
}

void shield_die( Entity @self , Entity @inflicter, Entity @attacker )
{
    //G_Print("^6DEAD\n"); //debug
    self.explosionEffect(50);

    gtEnemies[self.count].die(@attacker);
}

int shield_spawn(Vec3 location)
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
    //G_Print("^3Spawn SHIELD #"+enemyIndex+" "+"\n"); // debug

    // make temporary vec3 for the hitbox because i don't know how to
    Vec3 tmins(-28,-28,-42);
    Vec3 tmaxs(28,28,12);

    @eC.enemyEnt = @G_SpawnEntity("shield");
    @eC.enemyEnt.think = shield_think;
    @eC.enemyEnt.die = shield_die;
    @eC.enemyEnt.pain = shield_pain;
    eC.enemyEnt.moveType = MOVETYPE_TOSSSLIDE;
    eC.enemyEnt.solid = SOLID_YES;
    eC.enemyEnt.clipMask = MASK_PLAYERSOLID;
    eC.enemyEnt.setSize(tmins,tmaxs);
    eC.enemyEnt.type = ET_SPRITE;
    eC.enemyEnt.effects = EF_QUAD;
    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/shield.tga");
    eC.enemyEnt.frame = 40;
    eC.enemyEnt.takeDamage = DAMAGE_YES;
    eC.enemyEnt.health = 250;
    eC.enemyEnt.svflags = uint(SVF_BROADCAST);
    eC.enemyEnt.mass = 300;
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

    location.z +=26;
    eC.enemyEnt.origin = location;
    eC.enemyEnt.nextThink = levelTime;
    eC.nextPhaseThink = levelTime+500;
    eC.lastSeenTime = levelTime;
    eC.type = EN_SHIELD;
    eC.active = true;
    eC.range = 99999;
    eC.speed = 200;
    eC.damage = 6;
    eC.jumpSpeed = 300;

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
