/*
**
**  math.as by THRESHER
**      Idle and Support #warsow.na @ quakenet
**  date: 9/26/2009
**
**  notes: if you use this math.as file, please keep my credits in/give me credit :D
**
*/


// returns distance between two vectors
float VectorDistance( Vec3 _vec1, Vec3 _vec2 ) { return _vec1.distance( _vec2 ); }

// returns for value of PI
float valueOfPI() { return 3.141592f; }

// convert degrees to radians
float degtorad( float _deg )
{
    float _pi = valueOfPI();
        return _deg * ( _pi / 180 );
}

// convert radians to degrees
float radtodeg( float _rad )
{
    float _pi = valueOfPI();
        return _rad * ( 180 / _pi );
}

// these are just awesomeness.
float lengthdir_x( float _len, float _dir ) { return _len * cos( degtorad ( _dir ) ); }

float lengthdir_y( float _len, float _dir ) { return _len * -sin( degtorad ( _dir ) ); }

float lengthdir_z( float _len, float _dir ) { return _len * -tan( degtorad ( _dir ) ); }


/*

THIS IS IN PROGRESS

float TraceLine( int _sx, int _sy, int _sz, int _length )
{

    int _dx, _dy, _dz;
    float _pi = valueOfPI();

    for ( int i = 0; i < _length; i++ )
    {
        _dx = _sx;
        _dy = _sy;
        _dz = _sz;
    }
}
*/
