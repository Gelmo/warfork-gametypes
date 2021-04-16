// TODO: make people spec whoever is defrosting them

const uint FTAG_DEFROST_TIME = 1500;
const uint FTAG_INVERSE_HAZARD_DEFROST_SCALE = 5;
const uint FTAG_INVERSE_ATTACK_DEFROST_SCALE = 5;
const uint FTAG_DEFROST_ATTACK_DELAY = 2000;
//const uint FTAG_DEFROST_DECAY_DELAY = 500;
const uint FTAG_DEFROST_DECAY_SCALE = 2;
const float FTAG_DEFROST_RADIUS = 144.0f;

int prcYesIcon;
int prcShockIcon;
int prcShellIcon;
int[] defrosts(maxClients);
uint[] lastShotTime(maxClients);
int[] playerSTAT_PROGRESS_SELFdelayed(maxClients);
uint[] playerLastTouch(maxClients);
bool[] spawnNextRound(maxClients);
//String[] defrostMessage(maxClients);
bool doRemoveRagdolls = false;

Cvar ftagAllowPowerups("ftag_allowPowerups", "0", CVAR_ARCHIVE);
Cvar ftagAllowPowerupDrop("ftag_powerupDrop", "1", CVAR_ARCHIVE);
Cvar g_noclass_inventory( "g_noclass_inventory", "gb mg rg gl rl pg lg eb cells shells grens rockets plasma lasers bullets", 0 );
Cvar g_class_strong_ammo( "g_class_strong_ammo", "1 75 20 20 40 125 180 15", 0 ); // GB MG RG GL RL PG LG EB

// Vec3 doesn't have dot product ffs
float dot(const Vec3 v1, const Vec3 v2) {
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

void FTAG_giveInventory(Client @client) {
	// give the weapons and ammo as defined in cvars
    String othertoken, weakammotoken, ammotoken;
    String itemList = g_noclass_inventory.string;
    String ammoCounts = g_class_strong_ammo.string;

    client.inventoryClear();

    for ( int i = 0; ;i++ )
    {
        othertoken = itemList.getToken( i );
        if ( othertoken.len() == 0 )
            break; // done

        Item @item = @G_GetItemByName( othertoken );
        if ( @item == null )
            continue;

        client.inventoryGiveItem( item.tag );

        // if it's ammo, set the ammo count as defined in the cvar
        if ( ( item.type & IT_AMMO ) != 0 )
        {
            othertoken = ammoCounts.getToken( item.tag - AMMO_GUNBLADE );

            if ( othertoken.len() > 0 )
            {
                client.inventorySetCount( item.tag, othertoken.toInt() );
            }
        }
    }

    // give armor
    client.armor = 150;

    // select rocket launcher
    client.selectWeapon( WEAP_ROCKETLAUNCHER );
}

void FTAG_playerKilled(Entity @target, Entity @attacker, Entity @inflictor) {
	if(@target.client == null) {
		return;
	}

	if((G_PointContents(target.origin) & CONTENTS_NODROP) == 0) {
		if(target.client.weapon > WEAP_GUNBLADE) {
			GENERIC_DropCurrentWeapon(target.client, true);
		}
		target.dropItem(AMMO_PACK);

		if(ftagAllowPowerupDrop.boolean) {
			if(target.client.inventoryCount(POWERUP_QUAD) > 0) {
				target.dropItem(POWERUP_QUAD);
				target.client.inventorySetCount(POWERUP_QUAD, 0);
			}

			if(target.client.inventoryCount(POWERUP_SHELL) > 0) {
				target.dropItem(POWERUP_SHELL);
				target.client.inventorySetCount(POWERUP_SHELL, 0);
			}
		}
	}

	if(match.getState() != MATCH_STATE_PLAYTIME) {
		return;
	}

	cFrozenPlayer(target.client);

	GT_updateScore(target.client);
	if(@attacker != null && @attacker.client != null) {
		GT_updateScore(attacker.client);
	}
}

void FTAG_NewRound(Team @loser) {
	for(int i = 0; i < maxClients; i++) {
		Client @client = @G_GetClient(i);

		if(@client == null) {
			break;
		}

		if(client.team == loser.team()) {
			client.respawn(false);

			if(spawnNextRound[i]) {
				spawnNextRound[i] = false;
			}

			continue;
		}/* else if(!client.getEnt().isGhosting()) {
			client.inventoryGiveItem(HEALTH_LARGE);
		}*/

		// respawn players who connected during the previous round
		if(spawnNextRound[i]) {
			client.respawn(false);

			spawnNextRound[i] = false;
		}
	}

	Team @winner = G_GetTeam(loser.team() == TEAM_ALPHA ? TEAM_BETA : TEAM_ALPHA);
	winner.stats.addScore(1);
	G_AnnouncerSound(null, G_SoundIndex("sounds/announcer/ctf/score_team0" + int(brandom(1, 2))), winner.team(), false, null);
	G_AnnouncerSound(null, G_SoundIndex("sounds/announcer/ctf/score_enemy0" + int(brandom(1, 2))), loser.team(), false, null);

	G_Items_RespawnByType(IT_WEAPON, 0, 0);

	FTAG_DefrostTeam(loser.team());
}

void FTAG_ResetDefrostCounters() {
	for(int i = 0; i < maxClients; i++) {
		if(spawnNextRound[i]) {
			spawnNextRound[i] = false;
		}

		defrosts[i] = 0;
	}
}

bool GT_Command(Client @client, const String &cmdString, const String &argsString, int argc) {
	if(cmdString == "drop") {
		String token;
		for(int i = 0; i < argc; i++) {
			token = argsString.getToken(i);
			if(token.len() == 0) {
				break;
			}

			if(token == "fullweapon") {
				GENERIC_DropCurrentWeapon(client, true);
				GENERIC_DropCurrentAmmoStrong(client);
			} else if(token == "weapon") {
				GENERIC_DropCurrentWeapon(client, true);
			} else if(token == "strong") {
				GENERIC_DropCurrentAmmoStrong(client);
			} else {
				GENERIC_CommandDropItem(client, token);
			}
		}
		return true;
	} else if(cmdString == "gametype") {
		String response = "";
		Cvar fs_game("fs_game", "", 0);
		String manifest = gametype.manifest;
		response += "\n";
		response += "Gametype " + gametype.name + " : " + gametype.title + "\n";
		response += "----------------\n";
		response += "Version: " + gametype.version + "\n";
		response += "Author: " + gametype.author + "\n";
		response += "Mod: " + fs_game.string + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n";
		response += "----------------\n";
		G_PrintMsg(client.getEnt(), response);
		return true;
	}else if ( cmdString == "cvarinfo" ) {
		GENERIC_CheatVarResponse( client, cmdString, argsString, argc );
		return true;
	} else if(cmdString == "callvotevalidate") {
		String votename = argsString.getToken(0);
		if(votename == "ftag_powerups") {
			String voteArg = argsString.getToken(1);
			if(voteArg.len() < 1) {
				client.printMessage("Callvote " + votename + " requires at least one argument\n");
				return false;
			}

			if(voteArg != "0" && voteArg != "1") {
				client.printMessage("Callvote " + votename + " expects a 1 or a 0 as argument\n");
				return false;
			}

			int value = voteArg.toInt();

			if(value == 0 && !ftagAllowPowerups.boolean) {
				client.printMessage("Powerups are already disabled\n");
				return false;
			}

			if(value == 1 && ftagAllowPowerups.boolean) {
				client.printMessage("Powerups are already enabled\n");
				return false;
			}

			return true;
		}

		if(votename == "ftag_powerup_drop") {
			String voteArg = argsString.getToken(1);
			if(voteArg.len() < 1) {
				client.printMessage("Callvote " + votename + " requires at least one argument\n");
				return false;
			}

			if(voteArg != "0" && voteArg != "1") {
				client.printMessage("Callvote " + votename + " expects a 1 or a 0 as argument\n");
				return false;
			}

			int value = voteArg.toInt();

			if(value == 0 && !ftagAllowPowerupDrop.boolean) {
				client.printMessage("Powerup drop is already disabled\n");
				return false;
			}

			if(value == 1 && ftagAllowPowerupDrop.boolean) {
				client.printMessage("Powerup drop is already enabled\n");
				return false;
			}

			return true;
		}

		client.printMessage("Unknown callvote " + votename + "\n");
		return false;

	} else if(cmdString == "callvotepassed") {
		String votename = argsString.getToken(0);
		if(votename == "ftag_powerups") {
			ftagAllowPowerups.set(argsString.getToken(1).toInt() > 0 ? 1 : 0);

			// force restart to update
			match.launchState(MATCH_STATE_POSTMATCH);

			// if i do this, powerups spawn but are unpickable
			/*if(ftagAllowPowerups.boolean) {
				gametype.spawnableItemsMask |= IT_POWERUP;
			} else {
				gametype.spawnableItemsMask &= ~IT_POWERUP;
			}*/
		} else if(votename == "ftag_powerup_drop") {
			ftagAllowPowerupDrop.set(argsString.getToken(1).toInt() > 0 ? 1 : 0);
		}
		return true;
	}
	return false;
}

bool GT_UpdateBotStatus(Entity @ent) {
	// TODO: make bots defrost people
	return GENERIC_UpdateBotStatus(ent);
}

Entity @GT_SelectSpawnPoint(Entity @self) {
	// select a spawning point for a player
	// TODO: make players spawn near where they were defrosted?
	return GENERIC_SelectBestRandomSpawnPoint(self, "info_player_deathmatch");
}

String @GT_ScoreboardMessage(uint maxlen) {
	String scoreboardMessage = "";
	String entry;
	Team @team;
	Entity @ent;
	int i, t, readyIcon;

	for(t = TEAM_ALPHA; t < GS_MAX_TEAMS; t++) {
		@team = @G_GetTeam(t);
		// &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
		entry = "&t " + t + " " + team.stats.score + " " + team.ping + " ";

		if(scoreboardMessage.len() + entry.len() < maxlen) {
			scoreboardMessage += entry;
		}

		for(i = 0; @team.ent(i) != null; i++) {
			@ent = @team.ent(i);

			readyIcon = ent.client.isReady() ? prcYesIcon : 0;

			int playerID = (ent.isGhosting() && (match.getState() == MATCH_STATE_PLAYTIME)) ? -(ent.playerNum + 1) : ent.playerNum;

			if(gametype.isInstagib) {
				// "Name Clan Score Dfrst Ping R"
				entry = "&p " + playerID + " " + ent.client.clanName + " "
					+ ent.client.stats.score + " " + defrosts[ent.client.playerNum] + " " +
					+ ent.client.ping + " " + readyIcon + " ";
			} else {
				int carrierIcon;
				if(ent.client.inventoryCount(POWERUP_QUAD) > 0) {
					carrierIcon = prcShockIcon;
				} else if(ent.client.inventoryCount(POWERUP_SHELL) > 0) {
					carrierIcon = prcShellIcon;
				} else {
					carrierIcon = 0;
				}

				// "Name Clan Score Frags Dfrst Ping C R"
				entry = "&p " + playerID + " " + ent.client.clanName + " "
					+ ent.client.stats.score + " " + ent.client.stats.frags + " " + defrosts[ent.client.playerNum] + " "
					+ ent.client.ping + " " + carrierIcon + " " + readyIcon + " ";
			}

			if(scoreboardMessage.len() + entry.len() < maxlen) {
				scoreboardMessage += entry;
			}
		}
	}

	return scoreboardMessage;
}

void GT_updateScore(Client @client) {
	if(@client != null) {
		if(gametype.isInstagib) {
			client.stats.setScore(client.stats.frags + defrosts[client.playerNum]);
		} else {
			client.stats.setScore(int(client.stats.totalDamageGiven * 0.01) + defrosts[client.playerNum]);
		}
	}
}

void GT_ScoreEvent(Client @client, const String &score_event, const String &args) {
	// Some game actions trigger score events. These are events not related to killing
	// oponents, like capturing a flag
	if(score_event == "dmg") {
		if(match.getState() == MATCH_STATE_PLAYTIME) {
			GT_updateScore(client);

			if(@client == null) {
				return; // ignore falldamage
			}

			Entity @ent = G_GetEntity(args.getToken(0).toInt());
			if(@ent != null && @ent.client != null) {
				lastShotTime[ent.client.playerNum] = levelTime;
			}
		}
	} else if(score_event == "kill") {
		Entity @attacker = null;
		if(@client != null) {
			@attacker = @client.getEnt();
		}

		FTAG_playerKilled(G_GetEntity(args.getToken(0).toInt()), attacker, G_GetEntity(args.getToken(1).toInt()));
	} else if(score_event == "disconnect") {
		cFrozenPlayer @frozen = @FTAG_GetFrozenForPlayer(client);
		if(@frozen != null) {
			frozen.defrost();
		}

		/*if(playerIsFrozen[client.playerNum()]) {
		  playerFrozen[client.playerNum()].kill();
		  }*/
	}
}

void GT_PlayerRespawn(Entity @ent, int old_team, int new_team) {
	// a player is being respawned. This can happen from several ways, as dying, changing team,
	// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
	if(old_team == TEAM_SPECTATOR) {
		spawnNextRound[ent.client.playerNum] = true;
	} else if(old_team == TEAM_ALPHA || old_team == TEAM_BETA) {
		cFrozenPlayer @frozen = @FTAG_GetFrozenForPlayer(ent.client);

		if(@frozen != null) {
			frozen.defrost();
		}
	}

	if(ent.isGhosting()) {
		return;
	}

	if(gametype.isInstagib) {
		ent.client.inventoryGiveItem(WEAP_INSTAGUN);
		ent.client.inventorySetCount(AMMO_INSTAS, 1);
		ent.client.inventorySetCount(AMMO_WEAK_INSTAS, 1);
	} else {
		FTAG_giveInventory(ent.client);
	}

	// auto-select best weapon in the inventory
	if(ent.client.pendingWeapon == WEAP_NONE) {
		ent.client.selectWeapon(-1);
	}

	// add a teleportation effect
	ent.respawnEffect();
}

// Thinking function. Called each frame
void GT_ThinkRules() {
	if(match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished()) {
		match.launchState(match.getState() + 1);
	}

	GENERIC_Think();

	// print count of players alive and show class icon in the HUD

    Team @team;
    int[] alive( GS_MAX_TEAMS );

    alive[TEAM_SPECTATOR] = 0;
    alive[TEAM_PLAYERS] = 0;
    alive[TEAM_ALPHA] = 0;
    alive[TEAM_BETA] = 0;

    for ( int t = TEAM_ALPHA; t < GS_MAX_TEAMS; t++ )
    {
        @team = @G_GetTeam( t );
        for ( int i = 0; @team.ent( i ) != null; i++ )
        {
            if ( !team.ent( i ).isGhosting() )
                alive[t]++;
        }
    }

    G_ConfigString( CS_GENERAL, "" + alive[TEAM_ALPHA] );
    G_ConfigString( CS_GENERAL + 1, "" + alive[TEAM_BETA] );

	for(int i = 0; i < maxClients; i++) {
		Client @client = @G_GetClient(i);
		if(match.getState() != MATCH_STATE_PLAYTIME) {
			client.setHUDStat(STAT_MESSAGE_ALPHA, 0);
			client.setHUDStat(STAT_MESSAGE_BETA, 0);
			client.setHUDStat(STAT_IMAGE_BETA, 0);
		} else {
			client.setHUDStat(STAT_MESSAGE_ALPHA, CS_GENERAL);
			client.setHUDStat(STAT_MESSAGE_BETA, CS_GENERAL + 1);
		}
	}

	if(match.getState() >= MATCH_STATE_POSTMATCH) {
		return;
	}

	GENERIC_Think();

	for(int i = 0; i < maxClients; i++) {
		//defrostMessage[i] = "Defrosting:";
		Client @client = @G_GetClient(i);

		if(@client == null || FTAG_PlayerFrozen(@client)) {
			continue;
		}

		client.inventorySetCount(AMMO_GUNBLADE, 1);

		Entity @ent = client.getEnt();
		if(ent.health > ent.maxHealth) {
			ent.health -= (frameTime * 0.001f);
		}

		client.setHUDStat(STAT_PROGRESS_SELF, playerSTAT_PROGRESS_SELFdelayed[i]);
		if(playerLastTouch[i] < levelTime) {
			playerSTAT_PROGRESS_SELFdelayed[i] = 0;
		}

		/* check if player is looking at a frozen player and
		   show something like "Player (50%)" if they are */

		Vec3 origin = client.getEnt().origin;
		Vec3 eye = origin + Vec3(0, 0, client.getEnt().viewHeight);

		Vec3 dir, right, up;
		// unit vector
		client.getEnt().angles.angleVectors(dir, right, up);

		String msg;

		for(cFrozenPlayer @frozen = @frozenHead; @frozen != null; @frozen = @frozen.next) {
			if(client.team == frozen.client.team) {
				/* this compares the dot product of the vector from
				   player's eye and the model's center and the vector
				   from the player's eye to the model's top with the
				   dot product of the vector from the player's eye to
				   the model's center and the player's angle vector

				   it should work nicely from all angles and distances

				   TODO: it's actually stupid at close range since it
				   assumes you're looking at h1o
				 */

				Entity @model = @frozen.model;
				Vec3 mid = model.origin/* + (mins + maxs) * 0.5*/;

				if(origin.distance(mid) <= FTAG_DEFROST_RADIUS) {
					continue;
				}

				Vec3 mins, maxs;
				model.getSize(mins, maxs);

				Vec3 top = mid + Vec3(0, 0, FTAG_DEFROST_RADIUS);

				Vec3 eyemid = mid - eye;
				eyemid.normalize();
				Vec3 eyetop = top - eye;
				eyetop.normalize();

				if(dot(dir, eyemid) >= dot(eyetop, eyemid)) {
					msg += frozen.client.name + " (" + ((frozen.defrostTime * 100) / FTAG_DEFROST_TIME) + "%), ";
				}
			}
		}

		int len = msg.len();
		if(len != 0) {
			G_ConfigString(CS_GENERAL + 2 + i, msg.substr(0, len - 2));

			client.setHUDStat(STAT_MESSAGE_SELF, CS_GENERAL + 2 + i);
		} else {
			client.setHUDStat(STAT_MESSAGE_SELF, 0);
		}
	}

	/*for(int i = 0; i < maxClients; i++) {
	  if(defrostMessage[i].len() > 11) {
	  G_ConfigString(CS_GENERAL + 1 + i, defrostMessage[i].substr(1, 6));
	  G_GetClient(i).setHUDStat(STAT_MESSAGE_SELF, CS_GENERAL + 1 + i);
	  } else {
	  G_GetClient(i).setHUDStat(STAT_MESSAGE_SELF, 0);
	  }
	  }*/

	// if everyone on a team is frozen then start a new round
	if(match.getState() == MATCH_STATE_PLAYTIME) {
		int count;
		for(int i = TEAM_ALPHA; i < GS_MAX_TEAMS; i++) {
			@team = @G_GetTeam(i);
			count = 0;

			for(int j = 0; @team.ent(j) != null; j++) {
				if(!team.ent(j).isGhosting()) {
					count++;
				}
			}

			if(count == 1) {
				for(int h = 0; @team.ent(h) != null; h++) {
					G_CenterPrintMsg( @team.ent(h), "Last unfrozen teammate!\n" );
				}
			}

			if(count == 0) {
				FTAG_NewRound(team);
				break;
			}
		}
	}

	if(@frozenHead != null) {
		frozenHead.think();
	}

	if(doRemoveRagdolls) {
		G_RemoveDeadBodies();
		doRemoveRagdolls = false;
	}
}

bool GT_MatchStateFinished(int incomingMatchState) {
	// The game has detected the end of the match state, but it
	// doesn't advance it before calling this function.
	// This function must give permission to move into the next
	// state by returning true.
	if(match.getState() <= MATCH_STATE_WARMUP && incomingMatchState > MATCH_STATE_WARMUP && incomingMatchState < MATCH_STATE_POSTMATCH) {
		match.startAutorecord();
	}

	if(match.getState() == MATCH_STATE_POSTMATCH) {
		match.stopAutorecord();
	}

	return true;
}

void GT_MatchStateStarted() {
	// the match state has just moved into a new state. Here is the
	// place to set up the new state rules
	switch(match.getState()) {
		case MATCH_STATE_WARMUP:
			gametype.pickableItemsMask = gametype.spawnableItemsMask;
			gametype.dropableItemsMask = gametype.spawnableItemsMask;

			GENERIC_SetUpWarmup();

			for(int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++) {
				gametype.setTeamSpawnsystem(team, SPAWNSYSTEM_INSTANT, 0, 0, false);
			}

			break;

		case MATCH_STATE_COUNTDOWN:
			gametype.pickableItemsMask = 0;
			gametype.dropableItemsMask = 0;

			GENERIC_SetUpCountdown();

			break;

		case MATCH_STATE_PLAYTIME:
			gametype.pickableItemsMask = gametype.spawnableItemsMask;
			gametype.dropableItemsMask = gametype.spawnableItemsMask;

			GENERIC_SetUpMatch();

			FTAG_ResetDefrostCounters();

			// set spawnsystem type to not respawn the players when they die
			for(int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++) {
				gametype.setTeamSpawnsystem(team, SPAWNSYSTEM_HOLD, 0, 0, true);
			}

			break;

		case MATCH_STATE_POSTMATCH:
			gametype.pickableItemsMask = 0;
			gametype.dropableItemsMask = 0;

			GENERIC_SetUpEndMatch();

			break;

		default:
			break;
	}
}

void GT_Shutdown() {
	// the gametype is shutting down cause of a match restart or map change
}

void GT_SpawnGametype() {
	// The map entities have just been spawned. The level is initialized for
	// playing, but nothing has yet started.
}

void GT_InitGametype() {
	// Important: This function is called before any entity is spawned, and
	// spawning entities from it is forbidden. ifyou want to make any entity
	// spawning at initialization do it in GT_SpawnGametype, which is called
	// right after the map entities spawning.
	gametype.title = "Classic Freeze Tag";
	gametype.version = "0.9.5.6";
	gametype.author = "Mike^4JS";
	// Forked by Gelmo

	gametype.spawnableItemsMask = ( IT_WEAPON | IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH );
	if(!ftagAllowPowerups.boolean) {
		gametype.spawnableItemsMask &= ~IT_POWERUP;
	}
	if(gametype.isInstagib) {
		gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);
	}
	gametype.respawnableItemsMask = gametype.spawnableItemsMask;
	gametype.dropableItemsMask = gametype.spawnableItemsMask;
	gametype.pickableItemsMask = gametype.spawnableItemsMask;

	gametype.isTeamBased = true;
	gametype.isRace = false;
	gametype.hasChallengersQueue = false;
	gametype.maxPlayersPerTeam = 0;

	gametype.ammoRespawn = 20;
	gametype.armorRespawn = 25;
	gametype.weaponRespawn = 15;
	gametype.healthRespawn = 25;
	gametype.powerupRespawn = 90;
	gametype.megahealthRespawn = 20;
	gametype.ultrahealthRespawn = 60;
	gametype.readyAnnouncementEnabled = false;

	gametype.scoreAnnouncementEnabled = true;
	gametype.countdownEnabled = true;
	gametype.mathAbortDisabled = false;
	gametype.shootingDisabled = false;
	gametype.infiniteAmmo = false;
	gametype.canForceModels = true;
	gametype.canShowMinimap = true;
	gametype.teamOnlyMinimap = true;
	gametype.removeInactivePlayers = true;

	gametype.mmCompatible = true;

	gametype.spawnpointRadius = 256;
	if(gametype.isInstagib) {
		gametype.spawnpointRadius *= 2;
	}

	// set spawnsystem type to instant while players join
	for(int t = TEAM_PLAYERS; t < GS_MAX_TEAMS; t++) {
		gametype.setTeamSpawnsystem(t, SPAWNSYSTEM_INSTANT, 0, 0, false);
	}

	// define the scoreboard layout
	if(gametype.isInstagib) {
		G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %l 48 %p 18");
		G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Dfrst Ping R");
	} else {
		G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %i 52 %l 48 " + "%p 18 " + "%p 18");
		G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Frags Dfrst Ping " + "C " + " R");
	}

	// precache images that can be used by the scoreboard
	prcYesIcon = G_ImageIndex("gfx/hud/icons/vsay/yes");
	prcShockIcon = G_ImageIndex("gfx/hud/icons/powerup/quad");
	prcShellIcon = G_ImageIndex("gfx/hud/icons/powerup/warshell");

	// add commands
	G_RegisterCommand("drop");
	G_RegisterCommand("gametype");

	// add callvotes
	G_RegisterCallvote("ftag_powerups", "1 or 0", "bool", "Enables or disables powerups in Freeze Tag.");
	G_RegisterCallvote("ftag_powerup_drop", "1 or 0", "bool", "Enables or disables powerup dropping in Freeze Tag.");

	if(!G_FileExists("configs/server/gametypes/" + gametype.name + ".cfg")) {
		String config;
		// the config file doesn't exist or it's empty, create it
		config = "// '" + gametype.title + "' gametype configuration file\n"
			+ "// This config will be executed each time the gametype is started\n"
			+ "\n// " + gametype.title + " specific settings\n"
			+ "set ftag_allowPowerups \"0\"\n"
			+ "set ftag_powerupDrop \"1\"\n"
			+ "set g_noclass_inventory \"gb mg rg gl rl pg lg eb cells shells grens rockets plasma lasers bolts bullets\"\n"
            + "set g_class_strong_ammo \"1 75 20 20 40 125 180 15\" // GB MG RG GL RL PG LG EB\n"
			+ "\n// map rotation\n"
			+ "set g_maplist \"wfdm7 wfdm8 wfdm13 wfdm16 wfdm18 wfctf1 wfctf2 wfctf3 wfctf4\" // list of maps in automatic rotation\n"
			+ "set g_maprotation \"1\"   // 0 = same map, 1 = in order, 2 = random\n"
			+ "\n// game settings\n"
			+ "set g_scorelimit \"11\"\n"
			+ "set g_timelimit \"0\"\n"
			+ "set g_warmup_enabled \"1\"\n"
			+ "set g_warmup_timelimit \"1.5\"\n"
			+ "set g_match_extendedtime \"0\"\n"
			+ "set g_allow_falldamage \"1\"\n"
			+ "set g_allow_selfdamage \"1\"\n"
			+ "set g_allow_teamdamage \"0\"\n"
			+ "set g_allow_stun \"1\"\n"
			+ "set g_teams_maxplayers \"0\"\n"
			+ "set g_teams_allow_uneven \"0\"\n"
			+ "set g_countdown_time \"5\"\n"
			+ "set g_maxtimeouts \"3\" // -1 = unlimited\n"
			+ "set g_challengers_queue \"0\"\n"
			+ "\necho \"" + gametype.name + ".cfg executed\"\n";
		G_WriteFile("configs/server/gametypes/" + gametype.name + ".cfg", config);
		G_Print("Created default config file for '" + gametype.name + "'\n");
		G_CmdExecute("exec configs/server/gametypes/" + gametype.name + ".cfg silent");
	}
	G_Print("Gametype '" + gametype.title + "' initialized\n");
}
