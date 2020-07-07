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

/*enum ePrimaries FIXME enum
{
	PRIMARY_NONE, // used for pending test
	PRIMARY_MIN,
	PRIMARY_EBRL = PRIMARY_MIN,
	PRIMARY_RLLG,
	PRIMARY_EBLG
}

enum eSecondaries
{
	SECONDARY_NONE, // used for pending test
	SECONDARY_MIN = WEAP_PLASMAGUN,
	SECONDARY_PG = WEAP_PLASMAGUN,
	SECONDARY_RG = WEAP_RIOTGUN,
	SECONDARY_MG = WEAP_MACHINEGUN,
	SECONDARY_GL = WEAP_GRENADELAUNCHER,
	SECONDARY_GB = WEAP_GUNBLADE
}*/

const uint PRIMARY_NONE = 0; // used for pending test
const uint PRIMARY_MIN = 1;
const uint PRIMARY_EBRL = PRIMARY_MIN;
const uint PRIMARY_RLLG = 2;
const uint PRIMARY_EBLG = 3;

const uint SECONDARY_NONE = 0; // used for pending test
const uint SECONDARY_MIN = WEAP_PLASMAGUN;
const uint SECONDARY_PG = WEAP_PLASMAGUN;
const uint SECONDARY_RG = WEAP_RIOTGUN;
const uint SECONDARY_MG = WEAP_MACHINEGUN;
const uint SECONDARY_GL = WEAP_GRENADELAUNCHER;
const uint SECONDARY_GB = WEAP_GUNBLADE;

const int AMMO_EB = 15;
const int AMMO_RL = 15;
const int AMMO_LG = 180;
const int AMMO_PG = 140;
const int AMMO_RG = 15;
const int AMMO_MG = 150;
const int AMMO_GL = 10;
const int AMMO_GB = 1; // might as well spawn with it fully charged

const float PLAYER_ARMOR = 100.0f;

cPlayer@[] players( maxClients ); // array of handles
bool playersInitialized = false;

class cPlayer
{
	Client @client;

	//ePrimaries weapPrimary; FIXME enum
	//eSecondaries weapSecondary; 
	uint weapPrimary;
	uint weapSecondary;

	// fix for scoreboard/gb charge bugs
	//ePrimaries pendingPrimary; FIXME enum
	//eSecondaries pendingSecondary; 
	uint pendingPrimary;
	uint pendingSecondary;

	int killsThisRound; // int to avoid mismatch and honestly, could anyone but me get 2 trillion kills

	uint arms; // hopefully 2...
	uint defuses;

	bool dueToSpawn; // used for respawning during countdown

	bool isCarrier;

	uint oneVS;	// 1vs this many enemies on this round
	
	cPlayer( Client @player )
	{
		@this.client = @player;

		this.weapPrimary = PRIMARY_MIN;
		this.weapSecondary = SECONDARY_MIN;

		this.pendingPrimary = PRIMARY_NONE;
		this.pendingSecondary = SECONDARY_NONE;

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

		if ( this.pendingPrimary != PRIMARY_NONE )
		{
			this.weapPrimary = this.pendingPrimary;
			this.pendingPrimary = PRIMARY_NONE;
		}

		if ( this.pendingSecondary != PRIMARY_NONE )
		{
			this.weapSecondary = this.pendingSecondary;
			this.pendingSecondary = SECONDARY_NONE;
		}

		this.client.inventorySetCount( WEAP_GUNBLADE, 1 );
		this.client.armor = PLAYER_ARMOR;

		// XXX: old bomb would set the player's model depending on their
		//      primary weapon but i don't see the point

		// it dies if you don't cast...
		switch ( int( this.weapPrimary ) )
		{
			case PRIMARY_EBRL:
				this.client.inventoryGiveItem( WEAP_ROCKETLAUNCHER );
				this.client.inventoryGiveItem( WEAP_ELECTROBOLT );

				this.client.inventorySetCount( AMMO_ROCKETS, AMMO_RL );
				this.client.inventorySetCount( AMMO_BOLTS, AMMO_EB );

				this.client.inventorySetCount( AMMO_WEAK_ROCKETS, 0 );
				this.client.inventorySetCount( AMMO_WEAK_BOLTS, 0 );

				break;

			case PRIMARY_RLLG:
				this.client.inventoryGiveItem( WEAP_ROCKETLAUNCHER );
				this.client.inventoryGiveItem( WEAP_LASERGUN );

				this.client.inventorySetCount( AMMO_ROCKETS, AMMO_RL );
				this.client.inventorySetCount( AMMO_LASERS, AMMO_LG );

				this.client.inventorySetCount( AMMO_WEAK_ROCKETS, 0 );
				this.client.inventorySetCount( AMMO_WEAK_LASERS, 0 );

				break;

			case PRIMARY_EBLG:
				this.client.inventoryGiveItem( WEAP_ELECTROBOLT );
				this.client.inventoryGiveItem( WEAP_LASERGUN );

				this.client.inventorySetCount( AMMO_BOLTS, AMMO_EB );
				this.client.inventorySetCount( AMMO_LASERS, AMMO_LG );

				this.client.inventorySetCount( AMMO_WEAK_BOLTS, 0 );
				this.client.inventorySetCount( AMMO_WEAK_LASERS, 0 );

				break;

			default:
				assert( false, "player.as giveInventory: bad primary weapon" );

				break;
		}

		switch ( int( this.weapSecondary ) )
		{
			case SECONDARY_PG:
				this.client.inventoryGiveItem( WEAP_PLASMAGUN );

				this.client.inventorySetCount( AMMO_PLASMA, AMMO_PG );

				this.client.inventorySetCount( AMMO_WEAK_PLASMA, 0 );

				break;

			case SECONDARY_RG:
				this.client.inventoryGiveItem( WEAP_RIOTGUN );

				this.client.inventorySetCount( AMMO_SHELLS, AMMO_RG );

				this.client.inventorySetCount( AMMO_WEAK_SHELLS, 0 );

				break;

			case SECONDARY_MG:
				this.client.inventoryGiveItem( WEAP_MACHINEGUN );

				this.client.inventorySetCount( AMMO_BULLETS, AMMO_MG );

				//this.client.inventorySetCount( AMMO_WEAK_BULLETS, 0 );

				break;

			case SECONDARY_GL:
				this.client.inventoryGiveItem( WEAP_GRENADELAUNCHER );

				this.client.inventorySetCount( AMMO_GRENADES, AMMO_GL );

				this.client.inventorySetCount( AMMO_WEAK_GRENADES, 0 );

				break;

			case SECONDARY_GB:
				this.client.inventorySetCount( AMMO_GUNBLADE, AMMO_GB );

				break;

			default:
				assert( false, "player.as giveInventory: bad secondary weapon" );

				break;
		}

		this.client.selectWeapon( -1 );
	}

	String getInventoryLabel()
	{
		String label = "";

		switch ( int( this.weapPrimary ) )
		{
			case PRIMARY_EBRL:
				label += getWeaponIcon( WEAP_ELECTROBOLT )
					+ " " + getWeaponIcon( WEAP_ROCKETLAUNCHER );
				
				break;

			case PRIMARY_RLLG:
				label += getWeaponIcon( WEAP_ROCKETLAUNCHER )
					+ " " + getWeaponIcon( WEAP_LASERGUN );
				
				break;

			case PRIMARY_EBLG:
				label += getWeaponIcon( WEAP_ELECTROBOLT )
					+ " " + getWeaponIcon( WEAP_LASERGUN );
				
				break;

			default:
				assert( false, "player.as getInventoryLabel: switch hit default case" );

				break;
		}

		return label + " " + getWeaponIcon( this.weapSecondary );
	}


	void showPrimarySelection()
	{
		// this code shouldn't be reachable in insta
		assert( !gametype.isInstagib, "player.as showPrimarySelection: insta" );

		if ( this.client.team == TEAM_SPECTATOR || @this.client.getBot() != null )
		{
			return;
		}

		String command = "mecu \"Primary weapons\""
			+ " \"EB + RL\" \"weapselect eb; gametypemenu2\""
			+ " \"RL + LG\" \"weapselect rl; gametypemenu2\""
			+ " \"EB + LG\" \"weapselect lg; gametypemenu2\"";

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

	void showSecondarySelection()
	{
		// this code shouldn't be reachable in insta
		assert( !gametype.isInstagib, "player.as showSecondarySelection: insta" );

		if ( this.client.team == TEAM_SPECTATOR || @this.client.getBot() != null )
		{
			return;
		}

		// TODO: add brackets around current selection?

		this.client.execGameCommand( "mecu \"Secondary weapons\""
			+ " \"Plasmagun\" \"weapselect pg\""
			+ " \"Riotgun\" \"weapselect rg\""
			+ " \"Machinegun\" \"weapselect mg\""
			+ " \"Grenade Launcher\" \"weapselect gl\""
			+ " \"Strong Gunblade\" \"weapselect gb\""
		);
	}

	//void selectPrimaryWeapon( ePrimaries weapon ) FIXME enum
	void selectPrimaryWeapon( uint weapon )
	{
		this.pendingPrimary = weapon;
	}

	//void selectSecondaryWeapon( eSecondaries weapon ) FIXME enum
	void selectSecondaryWeapon( uint weapon )
	{
		this.pendingSecondary = weapon;
	}

	void selectWeapon( String &weapon )
	{
		String token;
		int len;

		String error;       // string containing unrecognised tokens
		uint errorCount = 0; // number of unrecognised tokens

		// :DD
		for ( int i = 0; ( len = ( token = weapon.getToken( i ) ).len() ) > 0; i++ )
		{
			if ( len != 2 )
			{
				continue;
			}

			token = token.toupper();

			// gg Switch expressions must be integral numbers
			// gg Case expressions must be constants

			if ( token == "EB" )
			{
				this.selectPrimaryWeapon( PRIMARY_EBRL );
			}
			else if ( token == "RL" )
			{
				this.selectPrimaryWeapon( PRIMARY_RLLG );
			}
			else if ( token == "LG" )
			{
				this.selectPrimaryWeapon( PRIMARY_EBLG );
			}
			else if ( token == "PG" )
			{
				this.selectSecondaryWeapon( SECONDARY_PG );
			}
			else if ( token == "RG" )
			{
				this.selectSecondaryWeapon( SECONDARY_RG );
			}
			else if ( token == "MG" )
			{
				this.selectSecondaryWeapon( SECONDARY_MG );
			}
			else if ( token == "GL" )
			{
				this.selectSecondaryWeapon( SECONDARY_GL );
			}
			else if ( token == "GB" )
			{
				this.selectSecondaryWeapon( SECONDARY_GB );
			}
			else
			{
				error += " " + token;

				errorCount++;
			}
		}

		if ( errorCount != 0 )
		{
			// no need to add a space before error because it's already there
			G_PrintMsg( @this.client.getEnt(), "Unrecognised token" + ( errorCount == 1 ? "" : "s" ) + ":" + error );
		}
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
