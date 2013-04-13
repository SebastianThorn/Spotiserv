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
  * The software that plays music, hallon and hallon-openal: https://github.com/Burgestrand/Hallon
  * The software that allows others to queue song, thin: https://github.com/macournoyer/thin
  * I'v been using pry alot to debug, so would like to give credit where credit is due, pry: https://github.com/pry/pry

I have only mashed up these to create a server, Spotiserv: https://github.com/SebastianThorn/Spotiserv
To start the server, simply type './start' in a linux console that have ruby, libspotify and the required gems.

The server anwsers to the following HTTP-GET requests:
  * `/add/<USER>/<SPOTIFY-TRACK-URI>` Returns an xml-file if successful, and adds the track to the URI to the playlist.
  * example: `192.168.0.189:8001/add/Sebastian/spotify:track:648j5ND8kMFMYXUGMWs5KP`
  * `/` Returns an html-page that renders the playlist into a table and populates it with the data from `/queue.xml`
  * `/queue.xml` Returns the current playlist as an xml-file
  * `/next` Returns an xml-file if successful, and changes the current track to the next in the playlist.


How to run on RPi, raspberrian (Soft-float!)
============================================
  * sudo apt-get update
  * sudo apt-get upgrade
  * sudo apt-get install ruby1.9.1-dev git-core libopenal-dev
  * wget http://developer.spotify.com/download/libspotify/libspotify-12.1.51-Linux-armv6-release.tar.gz
  * tar xvf libspotify-12.1.51-Linux-armv6-release.tar.gz
  * cd libspotify-12.1.51-Linux-armv6-release/
  * sudo make prefix=/usr/local install
  * cd ~
  * sudo gem install --no-ri --no-rdoc hallon hallon-openal thin active_support pry i18n builder
  * mkdir Git
  * cd Git/
  * git clone https://github.com/SebastianThorn/Spotiserv.git
  * cd Spotiserv/

Now you need to download the key-file from spotify, you can get it here: http://developer.spotify.com/technologies/libspotify/

Place it in ~/Git/Spotiserv/ Now you should be good to go with the server on a RPi running Raspbian.

`./start.rb [<username> [<password>]]`

Now it's time to play some good music!

`http://<IP>/add/Sebastian/spotify:track:6bOTe8T116DNpwp2H6Hxgh`

INFO: Console output seems to be quite heave on the PRi, not sure how to fix this yet.

TODO's
======
  * This weekend im also planning on making an android-application to work as client for the server
  * Add some sort of pause/play-toogle to the webserver
  * Comment the code
  * Add a Gemfile

Disclaimer
==========
While running this on RPi, you might have some playback issues.
