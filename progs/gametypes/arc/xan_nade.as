/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

//Multi-sploding grenades

void xanNade_Create( Entity @originalNade)
{
    Entity @newNade = @G_SpawnEntity( "xanNade" );
    Vec3 mins, maxs;
    originalNade.getSize(mins, maxs);

    newNade.modelindex = G_ModelIndex( "models/objects/projectile/glauncher/grenadestrong.md3" );
    @newNade.think = xanNade_think;
    newNade.type = originalNade.type;
    newNade.setSize( mins,maxs );
    newNade.solid = originalNade.solid;
    newNade.moveType = originalNade.moveType;
    newNade.svflags = originalNade.svflags;

    @newNade.owner = @originalNade.owner;
    newNade.damage = 40; // spreads out damage in 3 explosions
    newNade.nextThink = levelTime+800; // test    originalNade.nextThink
    newNade.mass = 1000;


    newNade.origin = originalNade.origin;

    newNade.velocity = originalNade.velocity;

    newNade.linkEntity();

    originalNade.freeEntity();
}

void xanNade_replace()
{
    // replace all nades with xanNades
    array<Entity @> @nade = @G_FindByClassname( "grenade");
    if (@nade != null)
    {
        xanNade_Create(@nade[0]);
    }
}


void xanNade_think(Entity @nade)
{
    //nade.moveType = MOVETYPE_NONE; // hover after first explosion
    nade.splashDamage( @nade.owner, 275, 25, 0, 0, MOD_EXPLOSIVE );
	nade.explosionEffect( 250 );
	nade.nextThink = levelTime+280;
	if (nade.damage == 38 ) // third explosion
	{
	    nade.freeEntity();
	}
	nade.damage -=1;
}

