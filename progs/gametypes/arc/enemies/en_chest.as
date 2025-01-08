/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

void chest_think( Entity @self)
{
    // chest doesn't need to think, just needs to sit still waiting to be shot
}

void chest_die( Entity @self , Entity @inflicter, Entity @attacker )
{
    cEnemy @eC; // enemyClass
    @eC = @gtEnemies[self.count];

    //G_Print("^6DEAD\n"); //debug
    self.explosionEffect(50);

    // drop items
    if (@attacker.client != null)
    {
        int randDrop = int(brandom(0,1.999f));
        switch (randDrop)
        {
            case 0: Loot.DropItem( @attacker, self.origin, ARMOR_RA);; break;
            case 1: Loot.DropItem( @attacker, self.origin, POWERUP_SHELL);; break;
            default: break;
        }

        Loot.DropItem( @attacker, self.origin, HEALTH_MEDIUM);
        Loot.DropItem( @attacker, self.origin, HEALTH_MEDIUM);

        /* control what chests drop
        switch (eC.type)
        {

        }
        */

    }

    gtEnemies[self.count].die(@attacker);
}

int chest_spawn(Vec3 location)
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
    //G_Print("^3Spawn CHEST #"+enemyIndex+" "+"\n"); // debug

    // make temporary vec3 for the hitbox because i don't know how to
    Vec3 tmins(-28,-28,-20);
    Vec3 tmaxs(28,28,8);

    @eC.enemyEnt = @G_SpawnEntity("chest");
    @eC.enemyEnt.think = chest_think;
    @eC.enemyEnt.die = chest_die;
    eC.enemyEnt.moveType = MOVETYPE_BOUNCE;
    eC.enemyEnt.solid = SOLID_YES;
    eC.enemyEnt.clipMask = MASK_PLAYERSOLID;
    eC.enemyEnt.setSize(tmins,tmaxs);
    eC.enemyEnt.type = ET_SPRITE;
    eC.enemyEnt.effects = EF_QUAD;
    eC.enemyEnt.modelindex = G_ImageIndex("gfx/en/chest.tga");
    eC.enemyEnt.frame = 40;
    eC.enemyEnt.takeDamage = DAMAGE_YES;
    eC.enemyEnt.health = 60;
    eC.enemyEnt.svflags = uint(SVF_BROADCAST);
    eC.enemyEnt.mass = 100;
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

    location.z += 16; // move up due to hitbox
    eC.enemyEnt.origin = location;
    eC.enemyEnt.nextThink = levelTime;
    eC.nextPhaseThink = levelTime+500;
    eC.lastSeenTime = levelTime;
    eC.type = EN_CHEST;
    eC.active = true;
    eC.range = 99999;
    eC.speed = 200;
    eC.damage = 0;
    eC.jumpSpeed = 0;

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

    @nearestPlayer = eC.action.scanNearestPlayer(300, true)
    ;
    if (@nearestPlayer != null)
    {
        eC.enemyEnt.freeEntity();
        eC.active = false;
        return NO_AVAILABLE_ENEMIES;
    }

    return enemyIndex;
}

