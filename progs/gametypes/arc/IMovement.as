
///*   By Xanthus
///*   Please don't use any of this as part of any CA gametype :D

///*****************************************************************
/// BASIC ENEMY MOVEMENT FUNCTIONS
///*****************************************************************

class IMovement
{
    Entity @selfEnt;

    bool canJump;
    bool onGround;
    Vec3 walkingVel;
    Vec3 lastFreePos;

    IMovement()
    {
    }

    ~IMovement()
    {
    }

    void Init(Entity @ownerEnt)
    {
        @this.selfEnt = @ownerEnt;
        walkingVel.set(0,0,0);
        this.lastFreePos = ownerEnt.origin;
    }

    void flyTowards(Vec3 target, int speed)
    {
        //G_Print("^1CHASE!\n");    // debug

        Vec3 noSpeed(0,0,0), newDir;

        newDir = this.getVelocityTowardsVec(this.selfEnt.origin,target,speed);

        // move up slightly if caught on ground / something while chasing
        if ( this.onGround )
        {
            newDir.set(newDir.x,newDir.y,200); // fly upwards a bit
        }

        this.selfEnt.velocity = newDir ;
    }

    void flyRoam(int speed)
    {
        Vec3 newDir = this.getVelocityTowardsVec(this.selfEnt.origin,this.selfEnt.origin+randDir(true),speed);

        // move up slightly if on ground.
        if ( this.onGround )
        {
            newDir.set(newDir.x,newDir.y,200); // fly upwards a bit
        }

        this.selfEnt.velocity = newDir;
    }

    void walkTowards(Vec3 target, int speed, int jumpSpeed)
    {
        Vec3 noSpeed(0,0,0), newDir;
        Vec3 mins,maxs;

        newDir = this.getVelocityTowardsVec(this.selfEnt.origin,target,speed);

        newDir.set(newDir.x,newDir.y,this.selfEnt.velocity.z); //keep z independant.

        // jump if player is above you
        this.selfEnt.getSize(mins,maxs);

        if ( target.z > ( this.selfEnt.origin.z + (mins.z+32) ) ) // if player origin is > than enemy origin plus difference in entity.min.z (players is 32). add the mins.z because it's a negative number.
        {
            if ( onGround ) // only jump on ground (look 1 unit below for solid)
            {
                //G_Print("^6There's a solid below, JUMP!\n"); //debug
                this.jumpTowards(target, jumpSpeed);
            }
        }

        this.walkingVel = newDir;
    }

    void walkRoam(int speed, int jumpSpeed)
    {
        Vec3 noSpeed(0,0,0), newDir;

        newDir = this.getVelocityTowardsVec(this.selfEnt.origin, this.selfEnt.origin+randDir(false), speed);

        newDir.set(newDir.x,newDir.y,this.selfEnt.velocity.z); //keep z independant.

        // if not moving, jump up (have to feed it a vec3) and go to last free pos
        if ( this.selfEnt.velocity == noSpeed )
        {
            this.selfEnt.origin = this.lastFreePos;

            this.jumpTowards(this.selfEnt.origin, jumpSpeed);
        }

        this.walkingVel = newDir;
    }

    void walking()
    {
        Vec3 rusrs(this.walkingVel.x,this.walkingVel.y,this.selfEnt.velocity.z);
        this.selfEnt.velocity = rusrs;

        //todo: figure out why the below doesn't work
        //G_Print("^1EntVel: "+this.selfEnt.velocity.x+" walkVel: "+this.walkingVel.x+" \n");
        //this.selfEnt.velocity.set(rusrs.x,rusrs.y, this.selfEnt.velocity.z); // leave Z independant for walkers
    }

    void stop()
    {
        this.walkingVel = Vec3(0,0,0);
    }

    void jumpTowards(Vec3 target, int jumpSpeed)
    {
        if (this.canJump == true)
        {
            int jumpHeight;

            jumpHeight = int(200+jumpSpeed+((target.z-this.selfEnt.origin.z)*1.25));

            // limit jump height
            if (jumpHeight > jumpSpeed * 3)
            {
                jumpHeight = jumpSpeed*3;
            }

            // jumpHeight = jumpSpeed+((target.z-self.origin.z)*1.5);

            Vec3 jumpVel(this.selfEnt.velocity.x,this.selfEnt.velocity.y, jumpHeight);
            this.selfEnt.velocity = jumpVel;

            this.canJump = false;
        }
    }

    Vec3 getVelocityTowardsVec(Vec3 original, Vec3 target, int speed)
    {
        Vec3 dir, dirAngles, velocity, y, z;

        dir = target - original; // move original point to 0,0,0 and get target's coordinate from that reference

        dirAngles = dir.toAngles(); // get the angles to target
        dirAngles.angleVectors( velocity, y, z); // change angle to vectors

        // multiply it by the speed to get what you need
        velocity *= speed;

        return velocity;
    }

    Vec3 randDir(bool threeD)
    {
        Vec3 randomDir;
        if (threeD == true)
        {
           randomDir = Vec3( brandom(-1000,1000),brandom(-1000,1000),brandom(-1000,1000) ); // random position
        }
        else
        {
            randomDir = Vec3( brandom(-1000,1000),brandom(-1000,1000),0); // random position
        }

        return randomDir;
    }

    bool unstuck()
    {
        bool unstuck = false;

        // todo: I just removed the solid code. see how it does.
        // if stuck inside monster, move to last free position
        Trace tr;
        Vec3 start,end, mins, maxs;
        start = end = this.selfEnt.origin;
        bool attemptLastFree;

        this.selfEnt.getSize(mins, maxs);

        if ( tr.doTrace( start, mins, maxs, end, this.selfEnt.entNum, MASK_PLAYERSOLID ) )
        {
            this.selfEnt.origin = this.lastFreePos;
            this.selfEnt.velocity.set(0,0,0) ; // stop so it can properly move again on next think.

            //this.walkingVel = Vec3(0,0,0); // walked into wall, don't keep moving into it

            unstuck = true;
        }
        else
        {
            this.lastFreePos = this.selfEnt.origin;
        }

        /* TODO: try to keep pushing it outside till it finds open space
        while ( tr.doTrace( start, mins, maxs, end, self.entNum, MASK_MONSTERSOLID ) )
        {
            //G_Print("^8UNSTUCK!\n"); //debug

            Vec3 newOrig;
            newOrig = self.origin;
            newOrig.z += 16;

            self.origin = newOrig;
            start = newOrig;
            end = newOrig;

            stuck = true;
        }
        */

        return unstuck;
    }

    void GroundCheck()
    {
        Trace tr;
        Vec3 start,end, mins, maxs;
        start.set(this.selfEnt.origin.x,this.selfEnt.origin.y,this.selfEnt.origin.z-2);
        end = start;

        this.selfEnt.getSize(mins, maxs);

        if ( tr.doTrace( start, mins, maxs, end, this.selfEnt.entNum, MASK_SOLID ) )
        {
            this.canJump = true;
            this.onGround = true;
        }
        else
        {
            this.onGround = false;
        }
    }

    Entity @scanNearestPlayer(int range, bool visible)
    {
        // first find the closest, then move towards target
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
				break;

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

    bool pathSolid(Vec3 pathEnd) // see if hitbox will collide with solid between here and end of path
    {
        Vec3 mins,maxs,center;
        Trace tr;

        this.selfEnt.getSize(mins,maxs);
        center = this.selfEnt.origin + ( 0.5 * ( maxs + mins ) );

        if ( tr.doTrace( this.selfEnt.origin, mins, maxs, center, this.selfEnt.get_entNum(), MASK_SOLID ))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

}


