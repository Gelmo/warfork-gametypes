
// midair Player class by THRESHER!  Idle & Support #warsow.na @ Quakenet!
// date: 9/26/09
// notes: if you use this players.as file, please keep my credits in/give me credit :D
class Player
{
    int kills;
    //int lastFire;
    float hp;
    float ap;
    bool hasControl;
    bool firstTouch;
    bool onGround;
    bool awardOnScreen;
    uint controlTime;
    uint AirControlTimer;
    uint lastGrenade;

    Player()
    {
        this.AirControlTimer = 1000;    // 1 second
        this.kills    = 0;
        this.hp       = 100;
        this.ap       = 100;
        //this.lastFire = 0;
        this.lastGrenade   = 0;
        this.hasControl    = true;
        this.awardOnScreen = false;
        this.firstTouch    = false;
        this.controlTime   = this.MakeTime( 3 );
        this.onGround      = false;
    }
    ~Player() {}

    // reset the clients kill count( for awards ) back to zero
    void resetKills()
    {
        this.kills = 0;
    }

    // used to check if the player touched the ground( for spawn movement really )
    void CheckTouch( Entity @ent )
    {
        Trace ln;
        Vec3 end, start, mins( 0, 0, 0 ), maxs( 0, 0, 0 );
            start = end = ent.origin;
            end.z -= 25;

        this.onGround = ln.doTrace( start, mins, maxs, end, ent.entNum, MASK_SOLID );
    }

    /*
        the following two functions were separated
        because it is better to have more control, right?
    */
    void resetHP()
    {
        this.hp = 100;
    }

    void resetAP()
    {
        this.ap = 100;
    }

    // returns a timer of _seconds long
    uint MakeTime ( int _seconds )
    {
        return levelTime + ( AirControlTimer * _seconds );
    }

    // called when the player respawns
    void resetControl ()
    {
        this.hasControl  = true;
        this.controlTime = this.MakeTime( 3 );
        this.onGround    = false;
    }

    // checking for air control
    void checkControl ()
    {
        if ( this.controlTime <= levelTime )
        {
            this.firstTouch = true;
            this.hasControl = false;
        }
        else
            this.hasControl = true;
    }

    // called usually when the player respawns/dies
    void reset ()
    {
        // shit to call when the player respawns
        this.resetControl();
        this.resetHP();
        this.resetAP();
        this.resetKills();
        this.lastGrenade = 0;
    }

}


// from bombs player.as
// gets our clients Player class
Player @GetClientPlayer( Client @client )
{
    return players[ client.playerNum ];
}


// from bombs player.as
Player[] players( maxClients );


/*
    Nice little function I set up to check for spawn air control
    and to check for the floor
*/
void PlayerThinkControl( Entity @ent )
{
    Player @p = GetClientPlayer( ent.client );

        // checking for air control and whatnot
        p.checkControl();

        if( !p.firstTouch && p.hasControl )
        {
                // checks for ground below players feet
                p.CheckTouch( ent );

                /*
                    check onGround, if true, we touched
                    ground after first spawn and no longer
                    have air control
                */
                if ( p.onGround )
                {
                    p.firstTouch = true;
                    p.hasControl = false;
                }
        }

    // air control switches
    switch ( g_mid_aircontrol.integer )
    {
        case 0:
        {
            if ( p.hasControl && !g_mid_spawnrape.boolean )
            {
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures | int( PMFEAT_AIRCONTROL ) );
                ent.client.set_pmoveMaxSpeed( P_WALK_SPEED ); // sets moving speed
            }
            else
            {
                Vec3 velocity;

                    ent.client.set_pmoveFeatures( ent.client.pmoveFeatures & ~int( PMFEAT_AIRCONTROL ) );
                    velocity = ent.velocity;
                    velocity.x = 0;
                    velocity.y = 0;
                    ent.velocity = velocity;
            }

            break;
        }

        case 1:
        {
            if ( p.hasControl && g_mid_spawnrape.boolean )
            {
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures & ~int( PMFEAT_AIRCONTROL ) );
                ent.client.set_pmoveMaxSpeed( P_AIR_SPEED ); // sets moving speed
            }
            else
            {
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures | int( PMFEAT_AIRCONTROL ) );
                ent.client.set_pmoveMaxSpeed( P_WALK_SPEED ); // sets moving speed
            }

            break;
        }

        case 2:
        {
            if( p.hasControl && !g_mid_spawnrape.boolean )
            {
                ent.client.set_pmoveMaxSpeed( P_WALK_SPEED );
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures | int( PMFEAT_AIRCONTROL ) );
            }
            else
            {
                ent.client.set_pmoveFeatures( ent.client.pmoveFeatures & ~int( PMFEAT_AIRCONTROL ) );
                ent.client.set_pmoveMaxSpeed( P_AIR_SPEED ); // sets moving speed
            }

            break;
        }

        default:
            break;
    }
}

// from bombs player.as
// resets everyones kill stats
void ResetPlayerKillStats ()
{
    for ( int i = 0; i < maxClients; i++ )
    {
        players[i].kills = 0;
    }
}
