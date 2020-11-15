cFrozenPlayer @frozenHead = null;

class cFrozenPlayer {
	int defrostTime;
	//uint lastTouch;

	Client @client;

	Entity @model;
	Entity @sprite;
	Entity @minimap;

	bool frozen;
	bool mateDefrosting;

	cFrozenPlayer @next;
	cFrozenPlayer @prev; // for faster removal

	cFrozenPlayer(Client @player) {
		if(@player == null) {
			return;
		}

		@this.prev = null;
		@this.next = @frozenHead;
		if(@this.next != null) {
			@this.next.prev = @this;
		}
		@frozenHead = @this;

		this.defrostTime = 0;
		//this.lastTouch = 0;
		this.mateDefrosting = false;

		@this.client = player;
		Vec3 vec = this.client.getEnt().origin;

		Vec3 mins, maxs;
		this.client.getEnt().getSize(mins, maxs);

		@this.model = @G_SpawnEntity("player_frozen");
		this.model.type = ET_PLAYER;
		this.model.moveType = MOVETYPE_TOSS;
		this.model.mass = 250; // no longer arbritary
		this.model.takeDamage = 1;
		this.model.origin = vec;
		this.model.velocity = this.client.getEnt().velocity;
		this.model.setSize(mins, maxs);
		this.model.angles = player.getEnt().angles;
		this.model.team = player.team;
		this.model.modelindex = this.client.getEnt().modelindex;
		this.model.solid = SOLID_NOT;
		this.model.skinNum = this.client.getEnt().skinNum;
		this.model.svflags = (player.getEnt().svflags & ~uint(SVF_NOCLIENT)) | uint(SVF_BROADCAST);
		this.model.effects = EF_ROTATE_AND_BOB | EF_GODMODE;
		this.model.frame = this.client.getEnt().frame;
		this.model.light = COLOR_RGBA(106, 192, 210, 128);
		this.model.linkEntity();

		@this.sprite = @G_SpawnEntity("capture_indicator_sprite");
		this.sprite.type = ET_RADAR;
		this.sprite.solid = SOLID_NOT;
		this.sprite.origin = vec;
		this.sprite.team = player.team;
		this.sprite.modelindex = G_ImageIndex("gfx/indicators/radar");
		this.sprite.frame = FTAG_DEFROST_RADIUS; // radius in case of a ET_SPRITE
		this.sprite.svflags = (this.sprite.svflags & ~uint(SVF_NOCLIENT)) | uint(SVF_BROADCAST) | SVF_ONLYTEAM;
		this.sprite.linkEntity();

		@this.minimap = @G_SpawnEntity("capture_indicator_minimap");
		this.minimap.type = ET_MINIMAP_ICON;
		this.minimap.solid = SOLID_NOT;
		this.minimap.origin = vec;
		this.minimap.team = player.team;
		this.minimap.modelindex = G_ImageIndex("gfx/indicators/radar_1");
		this.minimap.frame = 32; // size in case of a ET_MINIMAP_ICON
		this.minimap.svflags = (this.minimap.svflags & ~uint(SVF_NOCLIENT)) | uint(SVF_BROADCAST) | SVF_ONLYTEAM;
		this.minimap.linkEntity();

		frozen = true;

		if(!FTAG_LastAlive(@this.client)) {
			doRemoveRagdolls = true;
		}
	}

	void defrost() {
		// maybe it will fix bumping into invisible players
		//this.model.solid = SOLID_NOT;

		this.model.freeEntity();
		this.sprite.freeEntity();
		this.minimap.freeEntity();

		if(@this.prev != null) {
			@this.prev.next = @this.next;
		}
		if(@this.next != null) {
			@this.next.prev = @this.prev;
		}
		if(@frozenHead == @this) {
			@frozenHead = @this.next;
		}

		this.frozen = false;
		this.mateDefrosting = false;
	}

	void use(Entity @activator) {
		if(!this.frozen) {
			return;
		}

		// if player and activator in same team
		if(activator.client.team == this.client.team) {
			this.mateDefrosting = true;
			G_CenterPrintMsg(this.client.getEnt(), "Defrosting!");
			// G_CenterPrintMsg(this.client.getEnt(), "Being defrosted by " + activator.client.name + "!");
			// G_CenterPrintMsg(activator.client.getEnt(), "Defrosting " + this.client.name + "!");
		}
		if(@activator == @this.client.getEnt()) {
			// defrost slowly if they're in a sticky situation
			this.defrostTime += frameTime / FTAG_INVERSE_HAZARD_DEFROST_SCALE;

			if(this.defrostTime > FTAG_DEFROST_TIME) {
				Team @team = @G_GetTeam(this.client.team);
				for(int i = 0; @team.ent(i) != null; i++) {
					Entity @ent = @team.ent(i);
					if(@ent == @this.client.getEnt()) {
						G_CenterPrintMsg(team.ent(i), "You were defrosted!");
					} else {
						G_CenterPrintMsg(team.ent(i), this.client.name + " was defrosted!");
					}
				}

				G_PrintMsg(null, this.client.name + " was defrosted\n");

				this.client.respawn(false);
				this.defrost();
			}

			return;
		}

		if(@activator.client == null || activator.client.team != this.client.team) {
			return;
		}

		playerLastTouch[activator.client.playerNum] = levelTime;

		if(lastShotTime[activator.client.playerNum] + FTAG_DEFROST_ATTACK_DELAY >= levelTime) {
			this.defrostTime += frameTime / FTAG_INVERSE_ATTACK_DEFROST_SCALE;
		} else {
			this.defrostTime += frameTime;
		}

		if(this.defrostTime > FTAG_DEFROST_TIME) {
			Team @team = @G_GetTeam(this.client.team);
			for(int i = 0; @team.ent(i) != null; i++) {
				Entity @ent = @team.ent(i);

				if(@ent == @this.client.getEnt()) {
					G_CenterPrintMsg(team.ent(i), "You were defrosted!");
				} else {
					G_CenterPrintMsg(team.ent(i), this.client.name + " was defrosted!");
				}
			}

			G_PrintMsg(null, this.client.name + " was defrosted by " + activator.client.name + "\n");

			defrosts[activator.client.playerNum]++;

			this.client.respawn(false);
			this.defrost();
		}

		// defrost pie
		float frac = float(this.defrostTime) / float(FTAG_DEFROST_TIME);
		if(frac < 1) {
			if(lastShotTime[activator.client.playerNum] + FTAG_DEFROST_ATTACK_DELAY >= levelTime) {
				playerSTAT_PROGRESS_SELFdelayed[activator.client.playerNum] = -int(frac * 100);
			} else {
				playerSTAT_PROGRESS_SELFdelayed[activator.client.playerNum] = int(frac * 100);
			}
		} else {
			playerSTAT_PROGRESS_SELFdelayed[activator.client.playerNum] = 0;
		}

		/*G_Print(defrostMessage[activator.client.playerNum] + " -> ");
		defrostMessage[activator.client.playerNum] += " " + this.client.name + ",";
		G_Print(defrostMessage[activator.client.playerNum]+"\n");*/
	}

	void think() {
		this.model.effects |= EF_GODMODE; // doesn't work without this
		this.sprite.origin = this.model.origin;
		this.minimap.origin = this.model.origin;

		Trace tr;
		Vec3 center, mins, maxs, origin;
		//bool decay = true;
		origin = this.sprite.origin;

		array< Entity @ > @nearby = G_FindInRadius( origin, FTAG_DEFROST_RADIUS );

		for( uint i = 0; i < nearby.size(); i++ ) {
			Entity @target = nearby[ i ];

			if( @target.client == null ) {
				continue;
			}

			if( target.client.state() < CS_SPAWNED || target.isGhosting() ) {
				continue;
			}

			target.getSize(mins, maxs);
			center = target.origin + 0.5 * (maxs + mins);
			mins = maxs = 0;
			if(!tr.doTrace(origin, mins, maxs, center, target.entNum, MASK_SOLID)) {
				this.use(target);
				//decay = false;
			}
		}

		/*if(decay && this.defrostTime > 0 && this.lastTouch < levelTime - FTAG_DEFROST_DECAY_DELAY) {
			this.defrostTime -= this.defrostTime < frameTime ? this.defrostTime : frameTime;
		}*/

		if ( this.defrostTime < 0 ) {
            this.defrostTime = 0;
        }

        if ( this.mateDefrosting == false && this.defrostTime > 0 ) {
            this.defrostTime -= frameTime / FTAG_INVERSE_HAZARD_DEFROST_SCALE;
        }

		this.mateDefrosting = false;

		this.model.getSize(mins, maxs);

		int point = G_PointContents(this.model.origin + Vec3(0, 0, mins.z));
		if((point & CONTENTS_LAVA) != 0 || (point & CONTENTS_SLIME) != 0 || (point & CONTENTS_NODROP) != 0) {
			this.use(@this.client.getEnt()); // presumably they are in a pit/slime/lava
		}

		if(@this.next != null) {
			this.next.think();
		}
	}
}

bool FTAG_LastAlive(Client @client) {
	Team @team = @G_GetTeam(client.team);
	for(int i = 0; @team.ent(i) != null; i++) {
		if(!team.ent(i).isGhosting() && !FTAG_PlayerFrozen(team.ent(i).client)) {
			return false;
		}
	}

	return true;
}

void FTAG_DefrostAllPlayers() {
	for(cFrozenPlayer @frozen = @frozenHead; @frozen != null; @frozen = @frozen.next) {
		frozen.defrost();
	}
}

void FTAG_DefrostTeam(int team) {
	for(cFrozenPlayer @frozen = @frozenHead; @frozen != null; @frozen = @frozen.next) {
		if(frozen.client.team == team) {
			frozen.defrost();
		}
	}
}

bool FTAG_PlayerFrozen(Client @client) {
	return @FTAG_GetFrozenForPlayer(client) != null;
}

cFrozenPlayer @FTAG_GetFrozenForPlayer(Client @client) {
	for(cFrozenPlayer @frozen = @frozenHead; @frozen != null; @frozen = @frozen.next) {
		if(@frozen.client == @client) {
			return frozen;
		}
	}

	return null;
}
