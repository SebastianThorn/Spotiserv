#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a webserver that is suppose to handle incomming requests for Spotiserv

require "thin"
require "active_support/core_ext"

class SpotiThin

  def initialize (port, playlist, sp)

    ip = Socket.ip_address_list[1].ip_address
    puts "Starting thin, webserber"
    Thin::Server.start('0.0.0.0', port) do
      use Rack::CommonLogger
      
      # /add, to add a song to the playlist: /add/<user-code>/<spotify-uri>
      map "/add" do
        run Add_song.new sp
      end
      
      # /queue.xml, the ajax request from the browser
      map "/queue.xml" do
        run Queue.new playlist
      end
      
      # / and /index.html, to inform how the api works, nothing more
      map "/" do
        run Index.new
      end
      
    end

  end
  
  class Add_song
    def initialize (sp)
      @sp = sp
    end

    def call(env)
      # request-path
      rp = env["PATH_INFO"]
      puts env["HTTP_USER_AGENT"]
      puts "Addsong"
      puts "rp: #{rp}"
      user, track_uri = rp.match(/^\/(\w*)\/(.*)/)[1..2]
      puts "User: " + user
      puts "Track: " + track_uri
      track = Hallon::Track.new(track_uri).load
      @sp.add_to_playlist ({:track => track, :user => user})
      message = "#{track.name} - #{track.artist.name}, has been loaded into the playlist."
      html = %%<!DOCTYPE html>
<html>
  <head>
    <title>Spotiserv, add to queue</title>
  </head>
  <body style="background-color:black;color:white;margin-left:50px">
    #{message}
  </body>
</html>
%
        [200, {'Content-Type'=>'text/html'}, [html]]
    end
  end


  class Queue
    def initialize (playlist)
      @playlist = playlist
    end

    def call(env)
      xmlArray = []
      @playlist.take(20).each {|item| xmlArray.push({ :artist=>item[:track].artist.name,
                                             :song=>item[:track].name,
                                             :album=>item[:track].album.name,
                                             :user=>item[:user],
                                             :unit=>"N/A"})}
      xml = xmlArray.to_xml(:root => "item")
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
		txt="<table><tr><th>Artist</th><th>Track</th><th>Album</th><th>Name</th><th>Device</th></tr>";
		x=xmlhttp.responseXML.documentElement.getElementsByTagName("item");
		for (i=0;i<x.length;i++) {
		    if (i%2 == 1)
			txt=txt + "<tr>";
		    else
			txt=txt + "<tr class='alt'>";
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
    <title>SpotiServ, Playlist</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <link href='http://fonts.googleapis.com/css?family=Merriweather+Sans:400,700,800' rel='stylesheet' type='text/css'>
%

      css = """
    <style>
      body {background-color:white; font-family: 'Merriweather Sans', sans-serif; font-weight: 700; font-size:175%;}
      h1 {font-family: 'Merriweather Sans', sans-serif; font-weight: 800; font-size:300%;}
      table {border-collapse:collapse;width:100%}
      th, td {border: 2px solid #98bf21; padding:3px 7px 2px 7px;}
      th {text-align:center; padding-top:5px; padding-bottom:4px; background-color:#A7C942; color:#ffffff;}
      tr.alt td{color:#000000; background-color:#EAF2D3;}

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
    <div id="head"><h1>SpotiServ, PlayQueue</h1></div>
    <div id="queueInfo">
    </div>
  </center>
    
  </body>
</html>
%
      
      [200, {"Content-Type"=>"text/html"}, [html]]
    end
  end


end
