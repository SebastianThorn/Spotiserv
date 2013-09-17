#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a webserver that is suppose to handle incomming requests for Spotiserv

# Requirements
require "thin"
require "active_support/core_ext"

# Web-server that sends requests to the player-server, and sends info the users
class SpotiThin

  # Starting server, takes: ip, port and player-server (SpotiPlay)
  def initialize (ip, port, sp)
    puts "Starting thin, webserber on: http://" + ip + ":" + port.to_s

    # Registrates the resources for the web-server
    # All commands will be responded with an xml-file with information if they were a success or not.
    Thin::Server.start(ip, port) do
      use Rack::CommonLogger
      
      # Request: /add, to add a song to the playlist
      # /<udi>/add/<spotify-uri>
      # e.g. http://music.example.com/HXaIBXjI/add/spotify:track:2OcieDHRpksQQpIuQCOwPs
      # Response: ok/err/auth/priv
      map "/add" do
        run Add_song.new sp
      end
      
      # ! NOT IMPLEMENTED YET !
      # Request: /add_album, to add an entire album to the playlist
      # /<uid>/add_album/<spotify-uri>
      # e.g. http://music.example.com/jimmQEEp/add_album/spotify:album:4UjcMSiyv8QCiZ4O8gpzXS
      # Response: ok/err/auth/priv
      map "/add_album" do
        run Add_album.new sp
      end
      
      # ! DOES NOT WORK 100% !
      # Request: /playlist, set a playlist to play when there is no tracks in the local playlist, if no uri is sent, server will remove the current playlist
      # /<uid>/playlist/[spotify-uri]
      # e.g. http://music.example.com/pqMoOjUe/playlist/spotify:user:badgersweden:playlist:4B95CO3FINr1jH2okewLAY
      # e.g. http://music.example.com/pqMoOjUe/playlist
      # Response: ok/err/auth/priv
      map "/playlist" do
        run Playlist.new sp
      end

      # ! NOT IMPLEMENTED YET !
      # Request: /remove, remove a song from the playlist if you queued the track or if you are admin
      # /<uid>/remove/<index>
      # e.g. http://music.example.com/GprIrgRs/remove/23
      # Respone: ok/err/auth/priv
      map "/remove" do
        run Remove.new sp.playlist
      end

      # Request: /queue.xml, the ajax request from the browser
      # e.g http://music.example.com/queue.xml
      # See syntax.txt for xml-syntax
      map "/queue.xml" do
        run Get_queue.new sp
      end

      # ! DOES NOT WORK !
      # /next, skips the current song and starts the next instead.
      map "/next" do
        run Next_song.new sp
      end

      # /phone, sends a html5-page depending on your phone and resolution, the page pulls the xml-file with javascript.
      map "/phone" do
        run Phone.new
      end

      # /get, sends files back to the agent, such as css/javascript/images
      # e.g. http://music.example.com/get/css/main.css
      map "/get" do
        run Get_file.new
      end
      
      # / and /index.html, page with js that loads the xml-file.
      map "/" do
        run Index.new
      end
      
    end
  end
  
  # Resource that reads a user and a sporify-uri, and adds this to the playlist of the play-server.
  class Add_song
    def initialize (sp)
      @sp = sp
    end
    
    # TODO: remove some of the console-output
    def call(env)
      rp = env["PATH_INFO"]
      ip = env["REMOTE_ADDR"]
      puts env["HTTP_USER_AGENT"]
      puts "Addsong"
      puts "rp: #{rp}"
      user, track_uri = rp.match(/^\/(\w*)\/(.*)/)[1..2]
      puts "User: " + user
      puts "IP: " + ip
      puts "Track: " + track_uri
      track = Hallon::Track.new(track_uri).load
      @sp.add_to_playlist ({:track => track, :user => user, :ip => ip})
      xml = {:command=>"add", :track=>track.name, :artist=>track.artist.name,
        :album=>track.album.name, :user=>user}.to_xml
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class Next_song
    def initialize (sp)
      @sp = sp
    end

    def call(env)
      @sp.new_next
      xml = {:command=>"next"}.to_xml
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class Add_album
    
    def initialize (sp)
      @sp = sp
    end
    
    # TODO: remove some of the console-output
    def call(env)
      rp = env["PATH_INFO"]
      ip = env["REMOTE_ADDR"]
      puts env["HTTP_USER_AGENT"]
      puts "SptiThin.Thin.Add_album, rp: #{rp}"
      user, album_uri = rp.match(/^\/(\w*)\/(.*)/)[1..2]
      puts "User: " + user
      puts "IP: " + ip
      puts "Album: " + album_uri
      albumBrowse = Hallon::Album.new(album_uri).browse.load
      for track in albumBrowse.tracks
        @sp.add_to_playlist ({:track => track, :user => user, :ip => ip})
      end
      xml = {:command=>"add_album", :track=>track.name, :artist=>track.artist.name,
        :album=>track.album.name, :user=>user}.to_xml
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end
  
  class Playlist
    def initialize (sp)
      @sp = sp
    end
    
    def call(env)
      puts "SpotiThin.Thin.Playlist"
      rp = env["PATH_INFO"]
      puts "rp: #{rp}"
      playlist_uri = rp.match(/^\/(.*)/)[1]
      puts "Playlist: " + playlist_uri
      playlist = Hallon::Playlist.new(playlist_uri).load
      @sp.set_playlist(playlist)
      xml = {:command=>"playlist", :playlist=>playlist.name}.to_xml
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class Remove
    def initialize (playlist)
      @playlist = playlist
    end

    def call(env)
      puts "SpotiThin.Thin.Remove"
      rp = env["PATH_INFO"]
      puts "rp: #{rp}"
      index = rp.match(/^\/(.*)/)[1]
      puts "Index: " + index
      @playlist[index.to_i][:status] = "removed"
      xml = {:command=>"remove", :index=>index}.to_xml
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class Get_queue
    def initialize (sp)
      @sp = sp
    end

    def call(env)
      xmlArray = []
      @trunk = 5
      if (@sp.index < @trunk)
        @trunk = @sp.index
      end
      list = @sp.playlist.drop(@sp.index-@trunk).take(20)
      list.take(20).each {|item| xmlArray.push({ :artist=>item[:track].artist.name, :song=>item[:track].name,
                                                      :album=>item[:track].album.name, :user=>item[:user],
                                                      :unit=>"N/A", :status=>item[:status]})}
      xml = xmlArray.to_xml(:root => "item")
      [200, {"Content-Type"=>"text/xml"}, [xml]]
    end
  end

  class Phone
    def call(env)
      agent = env["HTTP_USER_AGENT"]
      # add some stuff here so we know what file to load
      html = File.open("web/clients/iphone5.html").read
      [200, {"Content-Type"=>"text/html"}, [html]]
    end
  end

  class Get_file
    def call(env)
      rp = env["PATH_INFO"]
      file = File.open("web/" + rp).read
      [200, {"Content-Type"=>"text/html"}, [file]]
    end
  end

  class Index
    def call(env)
      html = File.open("web/clients/fullhd.html").read
      [200, {"Content-Type"=>"text/html"}, [html]]
    end
  end

end
