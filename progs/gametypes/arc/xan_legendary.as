
///*   By Xanthus
///*   Please don't use any of this as part of any CA gametype :D

Entity @Legendary_Spawn(Entity @source, int legendary)
{
    if (@source == null)// an item might try to drop when it's not possible / supposed to.
    {
        return null;
    }

    Entity @legItem = @G_SpawnEntity("legendary_touch");
    legItem.type = ET_GENERIC;

    @legItem.touch = Legendary_Pickup;
    @legItem.think = legendary_item_think;
    @legItem.owner = @source;
    legItem.moveType = source.moveType;
    legItem.solid = source.solid;
    legItem.clipMask = source.clipMask;
    legItem.svflags = uint(SVF_BROADCAST);
    Vec3 mins, maxs;
    source.getSize(mins, maxs);
    legItem.setSize(mins, maxs);

    legItem.linkEntity();
    legItem.origin = source.origin;
    legItem.velocity = source.velocity;

    legItem.count = legendary;

    legItem.delay = levelTime + 1000; // can't pick up for half a second
    legItem.nextThink = levelTime + 1000;

    source.set_classname("legendary");
	
	return @legItem;
}

void Legendary_Think()
{
    // show white glow if you have legendary weapon
    for (int i = 0; i < maxClients; i++)
    {
        Client @client = @G_GetClient( i );

        // show white glow if you have legendary weapon
        if (gtPlayers[i].legendary == client.weapon)
        {
            client.getEnt().effects = EF_GODMODE;
        }
    }

    //Legendary Grenades
    array<Entity @> @replaceArray;
	Entity @replace;
    @replaceArray = @G_FindByClassname( "grenade");
	for(uint i=0; i<replaceArray.size();i++){
        if ( replaceArray[i].owner.client != null )
        {
            if ( gtPlayers[replaceArray[i].owner.client.get_playerNum()].legendary == WEAP_GRENADELAUNCHER)
            {
                xanNade_Create(@replaceArray[i]);
            }
        }
        replaceArray[i].set_classname("grenade_checked");
    }


    // Legendary Plasma

    @replaceArray = @G_FindByClassname( "plasma");
	for(uint i=0; i<replaceArray.size();i++)
	{
		if ( @replaceArray[i].owner.client != null )
        {
            if ( gtPlayers[replaceArray[i].owner.client.get_playerNum()].legendary == WEAP_PLASMAGUN)
            {
                Vec3 changedVel(replaceArray[i].owner.velocity.x-(replaceArray[i].velocity.x/50),replaceArray[i].owner.velocity.y-(replaceArray[i].velocity.y/50),replaceArray[i].owner.velocity.z-(replaceArray[i].velocity.z/25)+12);
                replaceArray[i].owner.set_velocity(changedVel);

                replaceArray[i].projectileSplashRadius*=2;
            }
        }
        replaceArray[i].set_classname("plasma_checked");
    }

	// Legendary Gunblade 
    @replaceArray = @G_FindByClassname( "gunblade_blast");
    for(uint i=0; i<replaceArray.size();i++)
	{
        if ( @replaceArray[i].owner.client != null )
        {
            if ( gtPlayers[replaceArray[i].owner.client.get_playerNum()].legendary == WEAP_GUNBLADE)
            {
                //todo: replace with something?
            }
        }

		replaceArray[i].set_classname("gunblade_blast_checked");
    }

    // Legendary items have special effects
    array<Entity @> @legItemArray = @G_FindByClassname( "legendary");
    for(uint i=0; i<legItemArray.size();i++)
	{
        legItemArray[i].set_classname("r_legendary");
        legItemArray[i].effects = EF_GODMODE|EF_ROTATE_AND_BOB;
    }
	
	// have to switch it back on for it to keep the effect
    @legItemArray = @G_FindByClassname( "r_legendary");
    for(uint i=0; i<legItemArray.size();i++)
	{
        legItemArray[i].set_classname("legendary");
    }
	
}

// only call this if self is already a client
void Legendary_Dmg(Entity @self, Entity @target, int dmg)
{
    // Legendary weapons that require damage
    if (self.client.weapon == gtPlayers[self.client.get_playerNum()].legendary)
    {
        // all legendaries do bonus dmg to enemies
        if (target.team != self.team)
        {
            target.health -= dmg*0.25;
            gtPlayers[self.client.get_playerNum()].waveDamage += dmg*0.25;
        }

        if (self.client.weapon ==  WEAP_ROCKETLAUNCHER)
        {
            // see if hurting self with rockets
            if (@self == @target)
            {
                float healingFactor = 1.0f;
                // don't overheal with shell
                if ( self.client.inventoryCount( POWERUP_SHELL ) > 0 )
                {
                    healingFactor = 0.2f;
                }
                if (self.client.armor > 0)
                {
                    self.health += (float(dmg)*healingFactor * (1.0f/3.0f) ); // heal 1/3rd towards health
                    self.client.armor += (float(dmg)*healingFactor * (2.0f/3.0f) ); // heal 2/3rds of armor
                }
                else
                {
                    self.health += float(dmg)*healingFactor;
                }
            }
        }

        if ( (self.client.weapon == WEAP_MACHINEGUN) && ((dmg == 10) or (dmg == 40)) ) //Bullets explode on hit
        {
            if ( (@target != @self) && (target.health > 0) ) // it was spawning rockets on myself, idk why
            {
                G_FireRocket( target.origin, Vec3(0,0,0), 100, 100, 11, 0, 0, @self );
                target.health+=6; // don't do an insane amount of dmg (bullet  11 dmg from rocket -6 = +5 dmg per bullet)
            }
        }

        if ( self.client.weapon == WEAP_RIOTGUN ) // stun enemies
        {
            Vec3 stop(0,0,0);
            target.velocity = stop;
            target.nextThink = levelTime + 1000;
        }

        if (self.client.weapon ==  WEAP_GUNBLADE)
        {
            // see if hurting self
            if (@self == @target)
            {
                if (self.client.armor > 0)
                {
                    self.health += (float(dmg)*0.95f * (1.0f/3.0f) ); // heal 1/3rd towards health
                    self.client.armor += (float(dmg)*0.95f * (2.0f/3.0f) ); // heal 2/3rds of armor
                }
                else
                {
                    self.health += float(dmg)*0.95f;
                }
            }
        }


        if (self.client.weapon == WEAP_LASERGUN) // heal teammates, drain from enemies
        {
            // don't drain health from chests
            if (@target == @gtEnemies[target.count].enemyEnt)
            {
                if (gtEnemies[target.count].type == EN_CHEST)
                {
                    return;
                }
            }

            if (self.team == target.team)
            {
                target.health +=2;
                if (target.health > 200)
                {
                    target.health = 200;
                }
            }
            else
            {
                self.health += 1.25f;
                if (self.health > 200)
                {
                    self.health = 200;
                }
            }
        }

        if (self.client.weapon ==  WEAP_GRENADELAUNCHER)
        {
            // more bonus damage from GL to enemies
            if (self.team != target.team)
            {
                target.health -= dmg*0.25;
                gtPlayers[self.client.get_playerNum()].waveDamage += dmg*0.25;
            }
        }

    }
}

void Legendary_Kill(Entity @self, Vec3 killed)
{
    if ( gtPlayers[self.get_playerNum()].legendary == WEAP_ELECTROBOLT)
    {
        self.client.inventorySetCount( AMMO_BOLTS, self.client.inventoryCount( AMMO_BOLTS)+1);
    }
}

void Legendary_Pickup(Entity @ent, Entity @other, const Vec3 planeNormal, int surfFlags)
{
    if ( (@other.client != null) && (ent.delay < int(levelTime) ) )
    {
        //first drop current legendary
        if (gtPlayers[other.client.get_playerNum()].legendary != 0)
        {
            // drop your weapon
            Entity @legItem;
            @legItem = other.dropItem( gtPlayers[other.client.get_playerNum()].legendary );
            Legendary_Spawn(@legItem, gtPlayers[other.client.get_playerNum()].legendary);
        }

        //set
        gtPlayers[other.client.get_playerNum()].legendary = ent.count;

        // explain the item
        switch (ent.count)
        {
            case WEAP_ROCKETLAUNCHER: other.client.printMessage("^5-[^7You picked up ^3Legendary Rocket Launcher!^7 No self-damage for rocket jumping.^5]-\n"); break;
            case WEAP_GRENADELAUNCHER: other.client.printMessage("^5-[^7You picked up ^3Legendary Grenade Launcher!^7 Grenades have 3 bigger explosions^5]-\n"); break;
            case WEAP_PLASMAGUN: other.client.printMessage("^5-[^7You picked up ^3Legendary Plasmagun!^7 Use plasmagun as a thruster to fly; Plasma has larger splash^5]-\n"); break;
            case WEAP_LASERGUN: other.client.printMessage("^5-[^7You picked up ^3Legendary Lasergun!^7 Drain HP from enemies or heal teammates^5]-\n"); break;
            case WEAP_GUNBLADE: other.client.printMessage("^5-[^7You picked up ^3Legendary Gunblade!^7 Each kill overcharges Gunblade (max:25)^5]-\n"); break;
            case WEAP_ELECTROBOLT: other.client.printMessage("^5-[^7You picked up ^3Legendary Electrobolt!^7 Get ammo back on kills^5]-\n"); break;
            case WEAP_RIOTGUN: other.client.printMessage("^5-[^7You picked up ^3Legendary Riotgun!^7 Stun enemies^5]-\n"); break;
            case WEAP_MACHINEGUN: other.client.printMessage("^5-[^7You picked up ^3Legendary Machinegun!^7 Bullets explode and hurt nearby enemies^5]-\n"); break;
            default: break;
        }

        ent.freeEntity();
    }
}

void Legendary_Destroy() // shouldn't need this with the think functions, they should remove themselves when the weapon isn't there
{
    array<Entity @> @legItem;
    @legItem = @G_FindByClassname( "legendary_touch");
    for(uint i=0; i<legItem.size();i++)
	{
        legItem[i].freeEntity();
    }

    @legItem = @G_FindByClassname( "legendary");
    for(uint i=0; i<legItem.size();i++)
	{
        legItem[i].freeEntity();
    }
}

void legendary_item_think(Entity @item)
{
    // remove if the original item is null
    if (@item.owner == null)
    {
        item.freeEntity();
        return;
    }
    else // when the weapon is picked up it no longer has a model
    {
        if (item.owner.modelindex == 0 )
        {
            item.freeEntity();
            return;
        }
    }
    item.nextThink = levelTime + 1000; // check once a second
}
