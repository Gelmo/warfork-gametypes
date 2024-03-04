/*
**
**  functions.as by THRESHER
**      Idle and Support #warsow.na @ quakenet
**  date: 9/26/2009
**
**  notes: if you use this functions.as file, please keep my credits in
**          or atleast include me in the credits :D
**
*/


uint MakeTimer ( int _seconds )
{
    return levelTime + ( 1000 * _seconds );
}



void clearAwards( Entity @ent )
{
    for ( int i = 0; i < 2; i++ )
        ent.client.addAward( "\n" );
}

// makes the size of the explosion given according to distance when
// the player is given an award( MidairAwards )
float ExplosionSize( float rdist )
{
    return ( degtorad( rdist ) ) * 64;
}


// for creating t3h awesome explosion rings :O
void ExplosionRings( Entity @ent, int dis, int rad )
{
    int _xx, _yy, _zz;
    float _pi = valueOfPI();
    Vec3 tmp = ent.origin;
        _xx = tmp.x;
        _yy = tmp.y;
        _zz = tmp.z;

    for( int i = 0; i < 360; i+=20 )
    {
        tmp.x = _xx + lengthdir_x( dis, i );
        tmp.y = _yy + lengthdir_y( dis, i );
        ent.origin= tmp ;
        ent.explosionEffect( rad );
    }

    tmp.x = _xx;
    tmp.y = _yy;
    tmp.z = _zz;
    ent.origin = tmp ;
}

void MidairSpecials( Entity @attacker, Entity @inflicter )
{
    if( inflicter.moveType == MOVETYPE_LINEARPROJECTILE )
        {

                float rocket_distance = VectorDistance( inflicter.origin2, inflicter.origin );
                int soundindex;
                float _pi = valueOfPI();



            if ( rocket_distance >= GOLD_MIDAIR && rocket_distance < DIAMOND_MIDAIR )
            {
                soundindex = G_SoundIndex("sounds/announcer/midair/gold0" + int( brandom( 1, 2 ) ) );
                    G_AnnouncerSound( null, soundindex, GS_MAX_TEAMS, false, null );
                    clearAwards( attacker );
                    attacker.client.addAward( S_COLOR_YELLOW + "GOLD MIDAIR!" );
                    //inflicter.explosionEffect( ExplosionSize( rocket_distance ) );
                    ExplosionRings( inflicter, 120, 32 );
            }

            if ( rocket_distance >= DIAMOND_MIDAIR && rocket_distance < BONGO_MIDAIR )
            {
                soundindex = G_SoundIndex("sounds/announcer/midair/diamond0" + int( brandom( 1, 2 ) ) );
                    G_AnnouncerSound( null, soundindex, GS_MAX_TEAMS, false, null );
                    clearAwards( attacker );
                    attacker.client.addAward( S_COLOR_CYAN + "DIAMOND MIDAIR!" );
                    ExplosionRings( inflicter, 60, 8 );
                    ExplosionRings( inflicter, 90, 16 );
                    ExplosionRings( inflicter, 120, 32 );

                    //inflicter.explosionEffect( ExplosionSize( rocket_distance ) );
            }

            if ( rocket_distance >= BONGO_MIDAIR )
            {
                soundindex = G_SoundIndex("sounds/announcer/midair/bongo0" + int( brandom( 1, 2 ) ) );
                    G_AnnouncerSound( null, soundindex, GS_MAX_TEAMS, false, null );
                    clearAwards( attacker );
                    attacker.client.addAward( S_COLOR_YELLOW + "King Of Bongo!" );
                    inflicter.explosionEffect( ExplosionSize( rocket_distance ) );
            }

        }
}


void MidairAwards( Entity @attacker, Entity @target )
{
        if ( @target != null && @target.client != null && @attacker != null && @attacker.client != null )
    {



            // Awards and shit need to go here.
            if ( @target != null && @target.client != null && @attacker != null && @attacker.client != null )
            {

                String aname, tname;

                aname = attacker.client.name;  // for dispalying attackers name
                tname = target.client.name;    // for displaying targets name

                Player @p = GetClientPlayer( attacker.client );
                    p.kills++;


                Player @a = GetClientPlayer( target.client );
                    a.resetKills();


                if( p.kills >= KA1 )
                {

                    switch ( p.kills )
                    {
                        case KA1:
                        {
                            attacker.client.addAward(S_COLOR_GREEN + "Leprechaun!");
                            G_CenterPrintMsg(null, S_COLOR_YELLOW + aname + " must have a leprechaun.");
                            break;
                        }
                        case KA2:
                        {
                            attacker.client.addAward(S_COLOR_GREY + "Needs More Cowbell.");
                            //G_AnnouncerSound( attacker.client, siEradication, attacker.team, true, null);
                            G_CenterPrintMsg(null, S_COLOR_YELLOW + aname + " needs some more cowbell.");
                            break;
                        }
                        case KA3:
                        {
                            attacker.client.addAward(S_COLOR_RED + "Wat.");
                            //G_AnnouncerSound( attacker.client, siEradication, attacker.team, true, null);
                            G_CenterPrintMsg(null, S_COLOR_YELLOW + aname + " is haxin.");
                            break;
                        }
                        case KA4:
                        {
                            attacker.client.addAward(S_COLOR_YELLOW + "GG.");
                            G_CenterPrintMsg(null, S_COLOR_YELLOW + aname + " called GG.");
                            break;
                        }
                        case KA5:
                        {
                            attacker.client.addAward(S_COLOR_MAGENTA + "AIMBOT :O");
                            //G_AnnouncerSound( attacker.client, siEradication, attacker.team, true, null);
                            G_CenterPrintMsg(null, S_COLOR_YELLOW + "Someone please callvote kick " + aname + " for " + tname );
                            break;
                        }

                        default:
                            break;
                    }

                }
                    /*
                    else
                    {
                        if( attacker.client.stats.score >= target.client.stats.score + 11 )
                            attacker.client.addAward(S_COLOR_YELLOW + attacker.client.stats.score + " midairs served" );
                    }
                    */
            }
    }
}
