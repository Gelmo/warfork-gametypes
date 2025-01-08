
///*   By Xanthus
///*   Please don't use any of this as part of any CA gametype :D

///*****************************************************************
/// BASIC ENEMY ACTIONS
///*****************************************************************

class IActions
{
    Entity @selfEnt;

    void Init(Entity @ownerEnt)
    {
        @this.selfEnt = @ownerEnt;
    }

    IActions()
    {
    }

    ~IActions()
    {	
    }

    Entity @scanNearestPlayer(int range, bool visible)
    {
        // first find the closest, then move towards target (249 of xdo_turret)
        Trace tr;
        Vec3 dir, newDir, mins,maxs,center; // 1,1,1 so that if they have line of site from center it'll work
        Vec3 origin = this.selfEnt.origin;
        array<Entity @> @target;
        Entity @stop = G_GetClient( maxClients - 1 ).getEnt(); // the last entity to be checked
        Entity @bestTarget = null;
        Entity @nullEnt = null;
        float bestRange = range + 1000;


		@target = @G_FindInRadius( origin, range );
		for(uint i=0; i<target.size(); i++)
		{
			if ( @target[i] == null || @target[i].client == null )
				continue;

			if ( target[i].client.state() < CS_SPAWNED )
				continue;

			if ( target[i].isGhosting() )
				continue;

			if ( gametype.isTeamBased && target[i].team == this.selfEnt.team )
				continue;

			// check if the player is visible
			if (visible)
			{
				target[i].getSize(mins,maxs);
				center = target[i].origin + ( 0.5 * ( maxs + mins ) );

				mins.set(-1,-1,-1); // use a small square from the center
				maxs.set(1,1,1);

				if ( !tr.doTrace( origin, mins, maxs, center, target[i].entNum, MASK_SOLID ) )
				{
					// found a visible enemy, compare ranges
					float thisRange = origin.distance( tr.endPos );
					if ( thisRange < bestRange )
					{
						bestRange = thisRange;
						@bestTarget = @target[i];
					}
				}
			}
			else
			{
				// compare ranges
				tr.doTrace( origin, mins, maxs, center, target[i].entNum, MASK_SOLID );

				float thisRange = origin.distance( tr.endPos );
				if ( thisRange < bestRange )
				{
					bestRange = thisRange;
					@bestTarget = @target[i];
				}
			}
		}
       

        // return bestTarget
        if (@bestTarget == null)
        {
            return null;
        }
        else
        {
            return @bestTarget;
        }
    }

    void attackRadius( int radius, int damage)
    {
        // attack enemy in radius
        array<Entity @> @target;
        Entity @stop = G_GetClient( maxClients - 1 ).getEnt(); // the last entity to be checked
        Vec3 origin = this.selfEnt.origin;

        while (true)
        {
            @target = @G_FindInRadius( origin, radius );
			for(uint i=0; i<target.size(); i++)
			{
				if ( @target[i] == null || @target[i].client == null )
					break;

				if ( target[i].client.state() < CS_SPAWNED )
					continue;


				if ( target[i].isGhosting() )
					continue;

				target[i].sustainDamage( @this.selfEnt, @this.selfEnt, this.selfEnt.origin, damage, 0, 0, MOD_HIT );
			}
        }
    }

    bool visibleEntity(Entity @target)
    {
        Trace tr;
        Vec3 mins,maxs,center,origin;

        selfEnt.getSize(mins,maxs);
        origin = this.selfEnt.origin + (0.5 * (maxs + mins) );

        target.getSize(mins,maxs);
        center = target.origin + ( 0.5 * ( maxs + mins ) );

        mins.set(-1,-1,-1); // use a small square from the center
        maxs.set(1,1,1);

        if ( !tr.doTrace( origin, mins, maxs, center, target.entNum, MASK_SOLID ) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    void Shoot(int weapon,Entity @source, Entity @target,int speed, int damage, int splash, int knockback)
    {
        Vec3 predictAngles;

        // if shooting projectile, calculate and aim for ground
        // don't shoot at the ground if you can't see it
        if ( (weapon == WEAP_ROCKETLAUNCHER) || (weapon == WEAP_GRENADELAUNCHER) || (weapon == WEAP_PLASMAGUN) )
        {
            float predictVariation = 0;
            float travelTime;
            float initialTravelTime;

            // add variation to plasma
            if (weapon == WEAP_PLASMAGUN)
            {
                predictVariation = random()*40-20; // 20 unit range of normal
            }

            travelTime = float(source.origin.distance(target.origin)) /  float(speed); // todo: see if distance is vec3
            initialTravelTime = travelTime; // used by GL when travelTime is capped below

            // do not predict more than 1 seconds ahead
            //todo: tweak this maybe. It's here to prevent over-shooting at walls too much / wiggling back and forth.
            // I've made it a bit lower for slow moving projectiles, they'll grossly overshoot at times.
            // possibly make this cap based on projectile speed.
            if (travelTime > 0.5)
            {
                travelTime = 0.5;
            }

            // if predictDistance is 0, use enemy origin. else use predicted angle
            predictAngles = target.origin;
            predictAngles.x += target.velocity.x*travelTime+predictVariation;
            predictAngles.y += target.velocity.y*travelTime+predictVariation;
            predictAngles.z += target.velocity.z/5;; // do not predict Z much (0.2 seconds worth of movement)  because of rising and falling and hitting the floor (mainly the hitting the floor)

            // if using rockets and other player is on ground (hacky check) and around level or below you
            if ( (weapon == WEAP_ROCKETLAUNCHER) && (target.velocity.z == 0) && (target.origin.z > selfEnt.origin.z-32) )
            {
                predictAngles.z -= 25;
            }
            if (weapon == WEAP_GRENADELAUNCHER) // shoot up a bit
            {
                if ( target.origin.z > source.origin.z) // if above aim a bit higher
                {
                    predictAngles.z += (target.origin.z - source.origin.z)/2;
                }
                // aim higher if target is further away
                predictAngles.z += (initialTravelTime*500)-100; //-xxx because close range it's shooting to high. but I like the scaling of *300
            }

            predictAngles -= source.origin ; // put self at 0,0,0, get angles to predictAngles
            predictAngles = predictAngles.toAngles();
        }
        // straight shot
        else
        {
            predictAngles = target.origin - source.origin;
            predictAngles = predictAngles.toAngles();
        }

        Entity @nade;
        Vec3 nadeVel;
        switch (weapon)
        {
            case WEAP_ELECTROBOLT: G_FireStrongBolt(source.origin, predictAngles, 99999, damage, knockback, 0, source); break;
            case WEAP_GUNBLADE: G_FireBlast( source.origin, predictAngles, speed, splash, damage, knockback, 0, source ); break;
            case WEAP_MACHINEGUN: G_FireBullet(source.origin, predictAngles, 99999, 0, damage, knockback, 0 , source ); break;
            case WEAP_PLASMAGUN: G_FirePlasma( source.origin, predictAngles, speed, splash, damage, knockback, 0, source); break;
            case WEAP_RIOTGUN: G_FireRiotgun( source.origin, predictAngles, 99999, splash, 20, damage, knockback, 0, source); break;
            case WEAP_ROCKETLAUNCHER: G_FireRocket( source.origin, predictAngles, speed, splash, damage, knockback, 0 , source); break;
            case WEAP_GRENADELAUNCHER: @nade = @G_FireGrenade( source.origin, predictAngles, speed, splash, damage, knockback, 0 , source);
                nadeVel = nade.velocity;
                nadeVel.z += 100;
                nade.velocity = nadeVel;
                nade.nextThink = levelTime+1500;
                break;
            default: G_Print("Incorrect Weapon\n"); break;// debug test
        }
    }

    // helper function.
    float turretAngleNormalize180( float angle )
    {
        angle = ( 360.0 / 65536 ) * ( int( angle * float( 65536 / 360.0 ) ) & 65535 );
        if ( angle > 180.0f )
            angle -= 360.0f;

        return angle;
    }

    void RocketJump(int power)
    {
        G_FireRocket(this.selfEnt.origin, Vec3(90,0,0),1000,power,20,power,0,this.selfEnt);
    }

}

