/*
Arcade Gametype for Warsow / Warfork
By Xanthus (originally made ~2014 or so)
*/

class cCapturePoint
{
    Entity @pointEnt;
    Entity @model;
    Entity @minimap;
    bool enabled; // whether it's going to be used or not
    bool active; // ready to spawn / touch / think
    bool spawned; // ready to be touched
    int spawnDelay; // 2 seconds
    uint spawnTimer;
    uint doomTimer;
    int doomDelay; // 15 seconds to get to it before it kills everyone

    void Init()
    {
        if (arc_portal.get_integer() == 0)
        {
            this.enabled = false;
            return;
        }
        else
        {
            this.enabled = true;
        }
        this.active = false;
        this.spawned = false;
        this.spawnTimer = 0;
        this.doomTimer = 0;
        switch( arc_portal.get_integer() )
        {
            case 1: /* 5/30 */ ARC_ControlPoint.spawnDelay = 5000; ARC_ControlPoint.doomDelay = 30000; break;
            case 2: /* 3/12 */ ARC_ControlPoint.spawnDelay = 3000; ARC_ControlPoint.doomDelay = 12000; break;
            case 3: /* 2/8 */ ARC_ControlPoint.spawnDelay = 2000; ARC_ControlPoint.doomDelay = 8000; break;
            default: break;
        }
        this.spawnDelay;
        this.doomDelay;

        @this.pointEnt = @G_SpawnEntity( "Point" );
        @this.pointEnt.think = point_think;
        this.pointEnt.team = TEAM_PLAYERS; // debug: was alpha
        this.pointEnt.type = ET_RADAR;
        this.pointEnt.modelindex = G_ImageIndex( "gfx/arc/arc_point" );
		this.pointEnt.frame = 132; // radius in case of a ET_SPRITE
		this.pointEnt.linkEntity();
        this.pointEnt.svflags = uint(SVF_NOCLIENT);
		

        @this.model = @G_SpawnEntity( "capture_indicator_model" );
        //this.model.team = TEAM_PLAYERS; // debug: was alpha
        this.model.type = ET_GENERIC;
        this.model.solid = SOLID_NOT;
        this.model.setupModel( "models/objects/capture_area/indicator.md3" );
        this.model.svflags = uint(SVF_NOCLIENT);
        this.model.effects = EF_ROTATE_AND_BOB;
        this.model.linkEntity();

        @this.minimap = @G_SpawnEntity("capture_indicator_minimap");
        this.minimap.team = TEAM_PLAYERS; // debug: was alpha
        this.minimap.type = ET_MINIMAP_ICON;
        this.minimap.solid = SOLID_NOT;
        this.minimap.modelindex = G_ImageIndex( "gfx/indicators/radar_1" );
        this.minimap.frame = 32;
        this.minimap.svflags = uint(SVF_NOCLIENT);
        this.minimap.linkEntity();



        this.pointEnt.nextThink = levelTime+100;
    }

    void Kill()
    {
        this.pointEnt.freeEntity();
        this.model.freeEntity();
        this.minimap.freeEntity();
    }

    void place(Vec3 position)
    {
        position.z += 64;
        if (this.pointEnt.origin == position) // spawn at a different spot
        {
            place( WaveController.ChooseSpawn() );
            return;
        }

        this.pointEnt.origin = position;
        this.model.origin = position;
        this.minimap.origin = position;
        this.spawned = true;
        this.pointEnt.svflags = uint(SVF_BROADCAST);
        this.model.svflags = uint(SVF_BROADCAST);
        this.minimap.svflags = uint(SVF_BROADCAST);

        this.pointEnt.frame = 532; // make it big at first, then shrink quickly to normal (132)
        this.minimap.frame = 232; // same as above

        this.Alert("Close the ^1Portal^7 ("+doomDelay/1000+" seconds)!");
    }

    void deactivate()
    {
        //if (this.enabled == true) // todo: do i need this?
        this.active = false;
        this.spawned = false;
        this.hide();
        this.setHUDStat(0);
    }

    void hide()
    {
        this.pointEnt.svflags = uint(SVF_NOCLIENT);
        this.model.svflags = uint(SVF_NOCLIENT);
        this.minimap.svflags = uint(SVF_NOCLIENT);
    }

    void activate()
    {
        //if (this.enabled == true) //todo: do I need this?
        this.active = true;
        this.spawned = false;
        this.pointEnt.nextThink = levelTime+100;
        this.spawnTimer = levelTime + this.spawnDelay;
    }

    void setHUDStat(int progress)
    {
        // Remove hud stat for everyone
        for(int i=0; i < maxClients; i++)
        {
            if ( @G_GetClient(i) != null )
            {
                // starting time = 0. divide progress out of doomDelay
                G_GetClient(i).setHUDStat( STAT_PROGRESS_SELF, progress );
            }
        }
    }

    cCapturePoint()
    {
    }

    ~cCapturePoint()
    {
    }

    void doom()
    {
        this.Alert("^1Portal ^7opened! Wave Lost!");

        for(int i=0; i < maxClients; i++)
        {
            if ( @G_GetClient(i) != null )
            {
                if ( !G_GetClient(i).getEnt().isGhosting() )
                {
                    G_GetClient(i).getEnt().sustainDamage( @this.pointEnt, @this.pointEnt, Vec3(0,0,0), 99999, 0, 0, MOD_HIT );
                }
            }
        }
    }

    void Alert(String message)
    {
        int i;

        for (i=0; i<maxClients; i++)
        {
            if (@G_GetClient(i) != null)
            {
                G_CenterPrintMsg(G_GetClient(i).getEnt(), message);
            }
        }
    }


}

void point_think(Entity @self) //todo why can't i put this in cCapturePoint
{
    if (ARC_ControlPoint.enabled = false)
    {
        return;
    }
    if (ARC_ControlPoint.active == false)
    {
        return;
    }

    // see if anyone is touching it
    array<Entity @> @target;
    Entity @stop = G_GetClient( maxClients - 1 ).getEnt(); // the last entity to be checked
    Vec3 origin = self.origin;

    if (ARC_ControlPoint.spawned == true)
    {
        // shrink to normal size after spawning (they shrink at a proportional rate and will be normal size at the same time)
        if (ARC_ControlPoint.pointEnt.frame > 132)
        {
            ARC_ControlPoint.pointEnt.frame -= 20;
            ARC_ControlPoint.minimap.frame -=10;
        }
        // show progress
        int startingTime = ARC_ControlPoint.doomTimer - ARC_ControlPoint.doomDelay;
        int progress = int(((levelTime - startingTime)*100.0f) / (ARC_ControlPoint.doomDelay)) ;
        //G_Print("^1Progress :"+progress+"\n"); // debug

        // slow down in the last 10% by half
        /*
        if (progress > 90)
        {
            ARC_ControlPoint.doomTimer += 50;
        }
        */

        // if there's no alive players in warmup, return and reset doomTimer
        if ( (match.getState() == MATCH_STATE_WARMUP) && (WaveController.AlivePlayers() == 0) )
        {
            ARC_ControlPoint.doomTimer = levelTime+ARC_ControlPoint.doomDelay;
        }

        // set hud stat for everyone
        ARC_ControlPoint.setHUDStat(progress);

        // ran out of time, doom time
        if (ARC_ControlPoint.doomTimer < levelTime)
        {
            ARC_ControlPoint.spawned = false;
            ARC_ControlPoint.spawnTimer = levelTime + ARC_ControlPoint.spawnDelay;
            ARC_ControlPoint.doom();
            WaveController.portalActivated = true;
            //G_Print("DOOM! Spawn:"+ARC_ControlPoint.spawnTimer+"\n"); // debug
        }

        // see if it was touched
		@target = @G_FindInRadius( origin, 100 );
		for(uint i=0;i<target.size();i++){
			if ( @target[i] == null || @target[i].client == null )
				break;



			if ( target[i].client.state() < CS_SPAWNED )
				continue;


			if ( target[i].isGhosting() )
				continue;

			//this was touched: Disable it
			//G_Print("^1Touched!\n"); // debug
			ARC_ControlPoint.spawned = false;
			ARC_ControlPoint.spawnTimer = levelTime + ARC_ControlPoint.spawnDelay;

			ARC_ControlPoint.setHUDStat(0);
			ARC_ControlPoint.hide();

			// get a point for closing the portal

			ARC_ControlPoint.Alert("^5"+target[i].client.get_name()+" closed the Portal!");
			WaveController.enemyCountRemaining-=1; // reduce enemies by 1 for closing portal

			gtPlayers[target[i].client.get_playerNum()].wavePortals += 1;
		}

    }

    //see when it'll spawn
    if ( (ARC_ControlPoint.spawned == false) && (ARC_ControlPoint.spawnTimer < levelTime) )
    {
        ARC_ControlPoint.place( WaveController.ChooseSpawn() );
        ARC_ControlPoint.doomTimer = levelTime + ARC_ControlPoint.doomDelay;
        //G_Print("^1Spawned! DoomTimer:"+ARC_ControlPoint.doomTimer+"\n"); // debug
    }


    self.nextThink = levelTime+50;
}
