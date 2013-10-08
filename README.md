Spotiserv
=========

Welcome to Spotiserv, a music-server that stream music from spotify.

Here is an old image of how it used to look with the standard theme, witch now is called "light".
![Alt text](http://i.imgur.com/1Zlw0sK.png "Old image")

Currently there is only a couple of smooth ways to use use and the server. (not really smooth as all, but they will be)
  * The built in iphone html5/js page, tho this needs to be updates to work with the new registation functionallity.
  * The app that is really buggy and therefore does not yet exist on play-store.
  * A web-browser and copy-pasting the registration-key and spotify-uri.

You will need a couple of things to make this work proper:
  * A Premium Spotify-account
  * An application key (get one here: https://developer.spotify.com/technologies/libspotify/ )

And that is it, now you are good to go!

If you have any problems or ideas to the server, don't hasitate to contact me on github and I will try to fix them.

The real purpose for this is at pre-parties (förfest in swedish) when you really dont have a good
way of playing music together, you either just have someone occupying a computer chair all evening.

Spotiserv is made of different pieces:
  * The software that plays music, hallon and hallon-openal: https://github.com/Burgestrand/Hallon
  * The software that allows others to queue song, thin: https://github.com/macournoyer/thin
  * I'v been using pry alot to debug, so would like to give some credit here, pry: https://github.com/pry/pry

I have only mashed up these to create a server, Spotiserv: https://github.com/SebastianThorn/Spotiserv

And this is how you run Spotiserv
---------------------------------
  * `git clone https://github.com/SebastianThorn/Spotiserv.git`
  * `cd Spotiserv`
  * `bundle install`
  * `chmod x+u start.rb`
  * Get an application-key from Spotify, then place it in the current directory
  * `./start.rb spotiserv.conf` and supply username and password if you didn't write them in spotiserv.conf
  * Start adding music and enjoy!

How to run on RPi, raspberrian (not sure if this longer works)
--------------------------------------------------------------
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
