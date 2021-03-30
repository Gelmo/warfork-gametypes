/*
Copyright (C) 2009-2010 Chasseur de bots

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

Cvar g_noclass_inventory( "g_noclass_inventory", "gb mg rg gl rl pg lg eb cells shells grens rockets plasma lasers bolts bullets", 0 );
Cvar g_class_strong_ammo( "g_class_strong_ammo", "1 75 20 20 40 125 180 15", 0 ); // GB MG RG GL RL PG LG EB

const float PLAYER_ARMOR = 250.0f;

cPlayer@[] players( maxClients ); // array of handles
bool playersInitialized = false;

class cPlayer
{
	Client @client;

	int killsThisRound; // int to avoid mismatch and honestly, could anyone but me get 2 trillion kills

	uint arms; // hopefully 2...
	uint defuses;

	bool dueToSpawn; // used for respawning during countdown

	bool isCarrier;

	uint oneVS;	// 1vs this many enemies on this round
	
	cPlayer( Client @player )
	{
		@this.client = @player;

		this.arms = 0;
		this.defuses = 0;

		this.dueToSpawn = false;

		this.isCarrier = false;
		
		this.oneVS = 0;

		@players[player.playerNum] = @this;
	}

	void giveInventory()
	{
		this.client.inventoryClear();

		if ( gametype.isInstagib )
		{
			this.client.inventoryGiveItem( WEAP_INSTAGUN );

			this.client.inventorySetCount( AMMO_INSTAS, 1 );
			this.client.inventorySetCount( AMMO_WEAK_INSTAS, 1 );

			this.client.selectWeapon( -1 );

			return;
		}
		else
		{
			String token, weakammotoken, ammotoken;
    		String itemList = g_noclass_inventory.string;
    		String ammoCounts = g_class_strong_ammo.string;

			for ( int i = 0; ;i++ )
            {
                token = itemList.getToken( i );
                if ( token.len() == 0 )
                    break; // done

                Item @item = @G_GetItemByName( token );
                if ( @item == null )
                    continue;

                this.client.inventoryGiveItem( item.tag );

                // if it's ammo, set the ammo count as defined in the cvar
                if ( ( item.type & IT_AMMO ) != 0 )
                {
                    token = ammoCounts.getToken( item.tag - AMMO_GUNBLADE );

                    if ( token.len() > 0 )
                    {
                        this.client.inventorySetCount( item.tag, token.toInt() );
                    }
                }
            }

    		this.client.armor = PLAYER_ARMOR;

            this.client.selectWeapon( WEAP_ROCKETLAUNCHER );
    	}

		// auto-select best weapon in the inventory
        if( this.client.pendingWeapon == WEAP_NONE )
    		this.client.selectWeapon( -1 );
	}

	void showPrimarySelection()
	{
		if ( this.client.team == TEAM_SPECTATOR || @this.client.getBot() != null )
		{
			return;
		}

		String command = "mecu \"Want to carry bomb?\"";

		if ( cvarEnableCarriers.boolean )
		{
			if ( this.isCarrier )
			{
				command += " \"Carrier opt-out\" \"carrier\"";
			}
			else
			{
				command += " \"Carrier opt-in\" \"carrier\"";
			}
		}

		// TODO: add brackets around current selection?

		this.client.execGameCommand( command );
	}

}

// since i am using an array of handles this must
// be done to avoid null references if there are players
// already on the server
void playersInit()
{
	// do initial setup (that doesn't spawn any entities, but needs clients to be created) only once, not every round
	if( !playersInitialized )
	{
		for ( int i = 0; i < maxClients; i++ )
		{
			Client @client = @G_GetClient( i );
			if ( client.state() >= CS_CONNECTING )
			{
				cPlayer( @client );
			}
		}
		playersInitialized = true;
	}
}

// using a global counter would be faster
uint getCarrierCount( int teamNum )
{
	uint count = 0;

	Team @team = @G_GetTeam( teamNum );

	for ( int i = 0; @team.ent( i ) != null; i++ )
	{
		Client @client = @team.ent( i ).client; // stupid AS...
		cPlayer @player = @playerFromClient( @client );

		if ( player.isCarrier )
		{
			count++;
		}
	}

	return count;
}

void resetKillCounters()
{
	for ( int i = 0; i < maxClients; i++ )
	{
		if ( @players[i] != null )
		{
			players[i].killsThisRound = 0;
			players[i].oneVS = 0;
		}
	}
}

cPlayer @playerFromClient( Client @client )
{
	cPlayer @player = @players[client.playerNum];

	// XXX: as of 0.18 this check shouldn't be needed as playersInit works
	if ( @player == null )
	{
		assert( false, "player.as playerFromClient: no player exists for client - state: " + client.state() );

		return cPlayer( @client );
	}

	return @player;
}

void team_CTF_genericSpawnpoint( Entity @ent, int team )
{
	ent.team = team;

	Trace trace;

	Vec3 start, end;
	Vec3 mins( -16, -16, -24 ), maxs( 16, 16, 40 );

	start = end = ent.origin;

	start.z += 16;
	end.z -= 1024;

	trace.doTrace( start, mins, maxs, end, ent.entNum, MASK_SOLID );

	if ( trace.startSolid )
	{
		G_Print( ent.classname + " starts inside solid, removing...\n" );

		ent.freeEntity();

		return;
	}

	if ( ent.spawnFlags & 1 == 0 )
	{
		// move it 1 unit away from the plane

		ent.origin = trace.endPos + trace.planeNormal;
	}
}

void team_CTF_alphaspawn( Entity @ent )
{
	team_CTF_genericSpawnpoint( ent, defendingTeam );
}

void team_CTF_betaspawn( Entity @ent )
{
	team_CTF_genericSpawnpoint( ent, attackingTeam );
}

void team_CTF_alphaplayer( Entity @ent )
{
	team_CTF_genericSpawnpoint( ent, defendingTeam );
}

void team_CTF_betaplayer( Entity @ent )
{
	team_CTF_genericSpawnpoint( ent, attackingTeam );
}