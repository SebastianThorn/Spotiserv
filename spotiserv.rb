#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a program made to act as a music-player-server for spotify.
# Multiple clients can be connected to the server at the same time, and queue different songs to the current playlist.
# The program will accept the following commands from clients (http-post/get):
#  http://server/*
#   Register to the server: POST reg/<username>/<rgb-code> ex: reg/Johan/00fa9a
#   Add a track to the playlist: POST add/<user-code>/<spotify-uri> ex: add/8djd7d/spotify:track:2hubQyLihYSKOeI01mS3vn
#   

# requirements
require "hallon"
require "hallon-openal"
require "socket"
require "thin"
require "pry"
require "active_support/core_ext"
require_relative "login.rb"

$ip = Socket.ip_address_list[1].ip_address
$port = 8001

class Spotiserv
  attr_accessor :player, :playlist

  def start
    # Setting up variables
    playing = false
    session = Hallon::Session.instance
    self.player = Hallon::Player.new(Hallon::OpenAL)
    self.playlist = []

    # Some exampels
    puts """Staring server at: http://#{$ip}:#{$port}
    queue.xml: http://#{$ip}:#{$port}/queue.xml
    Song 01: http://#{$ip}:#{$port}/add/Johan/spotify:track:4eNnqcB8gO1rW1K5PTFahs
    Song 02: http://#{$ip}:#{$port}/add/AndreasC/spotify:track:6h1Wkcm9qz79Xt1Qnp4n4A
    Song 03: http://#{$ip}:#{$port}/add/AndreasK/spotify:track:3LI4MmibTkXH5cGpCGZgyw
    Song 04: http://#{$ip}:#{$port}/add/Johan/spotify:track:4a8ZMNLB75047bY2I7oABt
    Song 05: http://#{$ip}:#{$port}/add/Thorn/spotify:track:4wIyDHaiXJVYlbusOg3Ldf
    Song 06: http://#{$ip}:#{$port}/add/Wadell/spotify:track:6UV7opcCk0XqqHePWvY0io
    Song 07: http://#{$ip}:#{$port}/add/Olle/spotify:track:648j5ND8kMFMYXUGMWs5KP
    Song 08: http://#{$ip}:#{$port}/add/Olle/spotify:track:56NkIxSZZiMpFP5ZNSxtnT
    Song 09: http://#{$ip}:#{$port}/add/Johan/spotify:track:2Gb7BLy6eX1bEuiJqxP3Sy
    Song 10: http://#{$ip}:#{$port}/add/Thorn/spotify:track:3cOoG6DKREfhlQ2kKtYmk8
    Song 11: http://#{$ip}:#{$port}/add/Peter/spotify:track:1tQ5TSr1tyeQUbHKBee0jv
    Song 12: http://#{$ip}:#{$port}/add/Adde/spotify:track:4Ld00UQYL3aPcK4yOnv0JP
    Song 13: http://#{$ip}:#{$port}/add/Kungen/spotify:track:1ky5BfVWOURVyXEPNsjQTY
    Song 14: http://#{$ip}:#{$port}/add/Stenson/spotify:track:1GwdUrz7DujSedNxnzVfqI
    Song 15: http://#{$ip}:#{$port}/add/Kohler/spotify:track:47KVHb6cOVBZbmXQweE5p7"""
  end

  def help
    puts """
##################
# SPOTISERV HELP #
##################

Variables, these are only here for debugging purposes only. They dont need to be public.
> Spotiserv.playlist
  This is an Array of hashes that has two keys, one is the track and the other is the name of the user that queued the track.
  => [{:track=>Hallon::Track, :user=>String}, ..]

> Spotiserv.status
  Keeps track of the state for Hallon::Player, so the server knows if it should call the play function after a song is added to the playlist.
  => true/false


    self.session = Hallon::Session.instance
    self.player = Hallon::Player.new(Hallon::OpenAL)
    self.playlist = []



"""
  end

  #TODO: INFO, Remove console output
  def p_play (track)
    Thread.new {
      puts "Playing: #{track.name} by #{track.artist.name}"
      self.player.play!(track)
      puts "Song ended: #{track.name} by #{track.artist.name}"
      puts "Removing from playlist.."
      self.playlist.shift
      if self.playlist.empty?
        puts "No more songs in playlist, stopping player"
        self.player.stop
      else
        puts "Starting nex song"
        p_play (self.playlist.first[:track])
      end
    }
  end

  #TODO: INFO, Remove console output
  def p_next
    unless self.playlist.empty?
      if self.playing
        "Next song"
      else
        puts "player is not playing a song right now, starting playback"
        self.playing = true
        p_next
      end
    else
      "no tracks in playlist, add some please"
    end
  end

  def p_pause
    self.player.pause
  end

  def p_resume
    self.player.resume
  end

  def play_pause
    if self.playing
      self.playing = false
      self.player.pause
      "pausing player"
    else
      self.paying = true
      "un-pausing player"
    end
  end
  
  def add_to_playlist (item)
    self.playlist.push (item)
    "Added #{item[:track].name} to the playlist!"
    unless self.player.status == :playing
      p_play (self.playlist.first[:track])
    end
  end

end

$ss = Spotiserv.new


def thinserver
  puts "Starting thin, webserber"
  Thin::Server.start('0.0.0.0', $port) do
    use Rack::CommonLogger

    # /add, to add a song to the playlist: /add/<user-code>/<spotify-uri>
    map "/add" do
      run Addsong.new
    end

    # /queue.xml, the ajax request from the browser
    map "/queue.xml" do
      run Queue.new
    end

    # / and /index.html, to inform how the api works, nothing more
    map "/" do
      run Index.new
    end

  end
end

#TODO: WARNING, Using $ss
class Addsong
  def call(env)

    # request-path
    rp = env["PATH_INFO"]
    puts "Addsong"
    puts "rp: #{rp}"
    user, track = rp.match(/^\/(\w*)\/(.*)/)[1..2]
    puts "User: " + user
    puts "Track: " + track
    $ss.playlist ({:track => Hallon::Track.new(track).load, :user => user})
    html = %%<!DOCTYPE html>
<html>
  <head>
    <title>Spotiserv, add to queue</title>
  </head>
  <body style="background-color:black;color:white;margin-left:50px">
    hello
  </body>
</html>
%
    [200, {'Content-Type'=>'text/html'}, [html]]
  end
end

#TODO: WARNING, Using $ss
#TODO: INFO, Remove console output
class Queue
  def call(env)
#    puts "In queues"
    xmlArray = []
    $ss.playlist.each {|item| xmlArray.push({ :artist=>item[:track].artist.name,
                                              :song=>item[:track].name,
                                              :album=>item[:track].album.name,
                                              :user=>item[:user],
                                              :unit=>"N/A"})}
#    puts xml
    xml = xmlArray.to_xml(:root => "item")
#    puts "created xml"
    [200, {"Content-Type"=>"text/xml"}, [xml]]
  end
end

class Index
  def call(env)
    js = %?
<script>
    function loadQueues() {
	var xmlhttp;
	var txt,x,xx,i;
	if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
	    xmlhttp=new XMLHttpRequest();
	} else {// code for IE6, IE5
	    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	}
	xmlhttp.onreadystatechange=function() {
	    if (xmlhttp.readyState==4 && xmlhttp.status==200) {
		txt="<table border='1' width='100%'><tr><th colspan='3'>spellista</th><th colspan='2'>köad av</th></tr><tr><th>artist</th><th>låt</th><th>album</th><th>namn</th><th>enhet</th></tr>";
		x=xmlhttp.responseXML.documentElement.getElementsByTagName("item");
		for (i=0;i<x.length;i++) {
		    txt=txt + "<tr>";
		    xx=x[i].getElementsByTagName("artist"); {
			try {
			    txt=txt + "<td>" + xx[0].firstChild.nodeValue + "</td>";
			} catch (er) {
			    txt=txt + "<td> </td>";
			}
                    }
		    xx=x[i].getElementsByTagName("song"); {
			try {
			    txt=txt + "<td>" + xx[0].firstChild.nodeValue + "</td>";
			} catch (er) {
			    txt=txt + "<td> </td>";
			}
                    }
		    xx=x[i].getElementsByTagName("album"); {
			try {
			    txt=txt + "<td>" + xx[0].firstChild.nodeValue + "</td>";
			} catch (er) {
			    txt=txt + "<td> </td>";
			}
                    }

		    xx=x[i].getElementsByTagName("user"); {
			try {
			    txt=txt + "<td>" + xx[0].firstChild.nodeValue + "</td>";
			} catch (er) {
			    txt=txt + "<td> </td>";
			}
                    }
		    xx=x[i].getElementsByTagName("unit"); {
			try {
			    txt=txt + "<td>" + xx[0].firstChild.nodeValue + "</td>";
			} catch (er) {
			    txt=txt + "<td> </td>";
			}
                    }

		    txt=txt + "</tr>";
		}
		txt=txt + "</table>";
		document.getElementById("queueInfo").innerHTML=txt;
	    }
        }
	xmlhttp.open("GET","queue.xml",true);
	xmlhttp.send();
    }

    function looper() {
      setInterval(function(){loadQueues()},3000);
    }

    window.onload = looper;
</script>
    ?

    head = %%
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <link href='http://fonts.googleapis.com/css?family=Merriweather+Sans:400,800' rel='stylesheet' type='text/css'>
%

    css = """
    <style>
      body {background-color:gray; font-family: ‘Metrophobic’, Arial, serif; font-weight: 400; font-size:150%}
      h1 {font-family: ‘Metrophobic’, Arial, serif; font-weight: 800; font-size:300%}
      table {border-collapse:collapse;}
      table, th, td {border: 2px solid black;}
      td {padding:10px;}

      #queueInfo {margin:40px;}
    </style>
"""

    html = %%<!DOCTYPE html>
<html>
  <head>
    #{head}
    #{css}
    #{js}
  </head>
  <body>
    
  <center>
    <div id="head"><h1>SpotiServ</h1></div>
    <div id="queueInfo">
    </div>
  </center>
    
  </body>
</html>
%

    [200, {"Content-Type"=>"text/html"}, [html]]
  end
end

$ss.start

jack = Hallon::Track.new("spotify:track:2hubQyLihYSKOeI01mS3vn").load
pstq = Hallon::Track.new("spotify:track:2N6hKvWyMMV1sHpTLecTF3").load
liza = Hallon::Track.new("spotify:track:66MNEC6GF5DEP3utyagq0J").load

puts """
Hello, and welcome to Spotiserv.

This is a spotify-server that plays music from spotify by adding them to a temporary playlist.
Anyone that is connected to the network can send spotify-uri's to the server and have them added
to a temporary playlist that the server will play from, if you have any problems of ideas to the
server, don't hasitate to contact me on github and I will add them to the server.

The real purpose for this is at pre-parties (förfest in swedish) when you really dont have a good
way of playing music together, you either just have someone occupying a computer chair all evening.

Spotiserv is made of different pieces;
1. The software that plays music, hallon and hallon-openal: https://github.com/Burgestrand/Hallon
2. The software that allows others to queue song, thin: https://github.com/macournoyer/thin
3. The software that controles these two from console, pry: https://github.com/pry/pry
   (pry is only used for debug and developing, use -c to load the server in this mode)

I have only mashed up these to create a server, Spotiserv: https://github.com/SebastianThorn/Spotiserv
To start the server, simply type './spotiserv' in a linux console that have ruby, libspotify and the required gems.

Debug-mode:
To start with the debug-mode, type './spotiserv -c', followed by 'thinserver', stop the webserver with C-c.
You can access the server directly by using the variable 'ss', use ss.help for more information.
From here you can play arounf with the variables and pause/resume the playback and other fun stuff.
There are 3 Hallon::Track already loaded into variables, 'jack, pstq, liza'
"""

binding.pry

puts "Shuting down.."
