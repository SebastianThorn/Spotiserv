Spotiserv
=========

Hello, and welcome to Spotiserv.

You will need a couple of things to make this work proper:
  * A Premium Spotify-account
  * An application key (get one here: https://developer.spotify.com/technologies/libspotify/ )

And that is it, now you are good to go!

This is a spotify-server that plays music from spotify by adding them to a temporary playlist.
Anyone that is connected to the network can send spotify-uri's to the server and have them added
to a temporary playlist that the server will play from, if you have any problems of ideas to the
server, don't hasitate to contact me on github and I will add them to the server.

The real purpose for this is at pre-parties (förfest in swedish) when you really dont have a good
way of playing music together, you either just have someone occupying a computer chair all evening.

Spotiserv is made of different pieces:
1. The software that plays music, hallon and hallon-openal: https://github.com/Burgestrand/Hallon
2. The software that allows others to queue song, thin: https://github.com/macournoyer/thin
x. i'v been using pry alot to debug, so would like to give credit where credit is due, pry: https://github.com/pry/pry

I have only mashed up these to create a server, Spotiserv: https://github.com/SebastianThorn/Spotiserv
To start the server, simply type './start' in a linux console that have ruby, libspotify and the required gems.

TODO's
======
  * Add some sort of pause/play-toogle to the webserver
  * Comment the code
  * Add a Gemfile

Disclaimer
==========
While running this on RPi, you might have some playback issues.
