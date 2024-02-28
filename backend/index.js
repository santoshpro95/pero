var app     = require( 'express' )();
var http    = require( 'http' ).createServer( app );
var io      = require( 'socket.io' )( http );
var download = require('download');


const PORT = 3001;

app.get( '/', function( req, res ) { 
    res.send( "Socket is working" );
});

app.get( '/file', function( req, res ) { 
    const filePath = "/pero.apk";
    res.download(
        filePath, 
        "pero.apk", // Remember to include file extension
        (err) => {
            if (err) {
                res.send({
                    error : err,
                    msg   : "Problem downloading the file"
                })
            }
    });
});

http.listen( PORT, function() {
    console.log( 'listening on *:' + PORT );
});

// socket connection state
io.on( 'connection', function( socket ) {

    // send when connected
    console.log('a user has connected!');

    // send when disconnected
    socket.on('disconnect', function() {
        console.log('user disconnected');
    });

    // send location
    socket.on('event', function (from, msg) {
        io.emit('getData', from);
      });

    // send chat 
    socket.on('chat', function (from, msg) {
        socket.broadcast.emit('getMessage', from);
    });

     // send draw
     socket.on('draw', function (from, msg) {
        socket.broadcast.emit('getDraw', from);
    });

    // send color
    socket.on('color', function (from, msg) {
        socket.broadcast.emit('getColor', from);
    });

     // send play
     socket.on('play', function (from, msg) {
        socket.broadcast.emit('getPlay', from);
    });
});
