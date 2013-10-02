#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a webserver that is suppose to handle incomming requests for Spotiserv

# Requirements
require "thin"
require "active_support/core_ext"

# Web-server that sends requests to the player-server, and sends info the users
class SpotiThin

  # Starting server, takes: ip, port and player-server (SpotiPlay)
  def initialize (ip, port, sp, command_privileges, user_hash)
    puts "Starting thin, webserber on: http://" + ip + ":" + port.to_s
    char_map = [(0..9), ('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten

    # Registrates the resources for the web-server
    # All commands will be responded with an xml-file with information if they were a success or not.
    Thin::Server.start(ip, port) do
      #use Rack::CommonLogger
      #set :logging, false

      # Request: /add, to add a song to the playlist
      # /add/<uid>/<spotify-uri>
      # e.g. http://music.example.com/HXaIBXjI/add/spotify:track:2OcieDHRpksQQpIuQCOwPs
      # Response: ok/err/auth/priv
      map "/addtrack" do
        run AddTrack.new sp, user_hash, command_privileges
      end
      
      # ! NOT IMPLEMENTED YET !
      # Request: /add_album, to add an entire album to the playlist
      # /add_album/<uid>/<spotify-uri>
      # e.g. http://music.example.com/jimmQEEp/add_album/spotify:album:4UjcMSiyv8QCiZ4O8gpzXS
      # Response: ok/err/auth/priv
      map "/addalbum" do
        run AddAlbum.new sp, user_hash, command_privileges
      end
      
      # ! DOES NOT WORK 100% !
      # Request: /playlist, set a playlist to play when there is no tracks in the local playlist,
      # if no uri is sent, server will remove the current playlist
      # /playlist/<uid>/[spotify-uri]
      # e.g. http://music.example.com/pqMoOjUe/playlist/spotify:user:badgersweden:playlist:4B95CO3FINr1jH2okewLAY
      # e.g. http://music.example.com/pqMoOjUe/playlist
      # Response: ok/err/auth/priv
      map "/playlist" do
        run Playlist.new sp, user_hash, command_privileges
      end

      # ! NOT IMPLEMENTED YET !
      # Request: /remove, remove a song from the playlist if you queued the track or if you are admin
      # /remove/<uid>/<index>
      # e.g. http://music.example.com/GprIrgRs/remove/23
      # Respone: ok/err/auth/priv
      map "/remove" do
        run Remove.new sp, user_hash, command_privileges
      end

      # Request: /queue.xml, the ajax request from the browser
      # e.g http://music.example.com/queue.xml
      # See syntax.txt for xml-syntax
      map "/queue.xml" do
        run GetQueue.new sp, user_hash, command_privileges
      end

      # ! DOES NOT WORK !
      # /next, skips the current song and starts the next instead.
      map "/nexttrack" do
        run NextTrack.new sp, user_hash, command_privileges
      end

      # /phone, sends a html5-page depending on your phone and resolution, the page pulls the xml-file with javascript.
      map "/phone" do
        run Phone.new
      end

      # /get, sends files back to the agent, such as css/javascript/images
      # e.g. http://music.example.com/get/css/main.css
      map "/getfile" do
        run GetFile.new
      end

      # Request: /register, registers the client to the server
      # /register/<username>/<android|ios|pc|other>/[key]
      # e.g. http://music.example.com/register/thorn/android/muusic
      # Response: command:register, response:ok|err, uid:<random-id>, role:<client|admin>
      map "/register" do
        run Register.new user_hash, command_privileges, char_map
      end

      # Request: /isreg, checks if the client is regstrated or not
      # /isreg/<uid>
      # e.g. http://music.example.com/isreg/0jA5Rwg1gNQ7h8Pc
      # Response: command:isreg, response:ok|auth|err
      map "/isreg" do
        run IsReg.new user_hash
      end
      
      # / and /index.html, page with js that loads the xml-file.
      map "/" do
        run Index.new
      end
      
    end
  end

  # Superclass to all other webrequests, contains a logger, just run 'log(env)' to print a log-message with timestamp to the terminal.
  class WebLog
    def log(env)
      if env.class == Hash
        rm = env.fetch("REQUEST_METHOD")
        rp = env.fetch("REQUEST_PATH")
        addr = env.fetch("REMOTE_ADDR")
        puts "[LOG] #{Time.new.strftime "[%d/%b/%Y %H:%M:%S.%L]"} #{self.class.to_s} [#{addr} #{rm} #{rp}]"
      elsif env.class == String
        puts env
      end
    end
  end

  # Superclass to most other webrequests, contains userchecks and initializer.
  class WebRequest < WebLog
    def initialize (sp, user_hash, command_privileges)
      @sp = sp
      @user_hash = user_hash
      @command_privileges = command_privileges
    end
    
    def can_call? (user_id, user_hash, command, command_privileges)
      if user_hash[user_id].nil?
        return false
      else
        user_hash[user_id][:time] = Time.new
        return true
      end
    end
  end

  # Resource that reads a user and a sporify-uri, and adds this to the playlist of the play-server.
  class AddTrack < WebRequest
    def call(env)
      rp = env["PATH_INFO"]
      puts "\nAddTrack"
      puts "Request: #{rp}"
      user_id, track_uri = rp.match(/^\/(\w*)\/(.*)/)[1..2]
      puts "UID: " + user_id
      puts "Track-URI: " + track_uri
      if can_call? user_id, @user_hash, self.class.to_s.split(":").last, @command_privileges
        track = Hallon::Track.new(track_uri).load
        puts "Can call\n"
        @sp.add_to_playlist ({:track => track, :user_id => user_id, :username => @user_hash[user_id][:username]})
        xml = {:command => "add", :result => "ok", :track=>track.name, :artist=>track.artist.name,
          :album=>track.album.name}.to_xml(:root => "response")
      else
        puts "Can't call due to auth"
        xml = {:command => "add", :response => "auth"}.to_xml(:root => "response")
      end
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class NextTrack < WebRequest

    def call(env)
      @sp.new_next
      xml = {:command=>"next"}.to_xml(:root => "response")
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class AddAlbum < WebRequest
    def call(env)
      rp = env["PATH_INFO"]
      puts env["HTTP_USER_AGENT"]
      puts "SptiThin.Thin.Add_album, rp: #{rp}"
      user, album_uri = rp.match(/^\/(\w*)\/(.*)/)[1..2]
      puts "User: " + user
      puts "Album: " + album_uri
      album_browse = Hallon::Album.new(album_uri).browse.load
      for track in album_browse.tracks
        @sp.add_to_playlist ({:track => track, :user => user})
      end
      xml = {:command=>"add_album", :track=>track.name, :artist=>track.artist.name,
        :album=>track.album.name, :user=>user}.to_xml(:root => "response")
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end
  
  class Playlist < WebRequest
    def call(env)
      puts "SpotiThin.Thin.Playlist"
      rp = env["PATH_INFO"]
      puts "rp: #{rp}"
      playlist_uri = rp.match(/^\/(.*)/)[1]
      puts "Playlist: " + playlist_uri
      playlist = Hallon::Playlist.new(playlist_uri).load
      @sp.set_playlist(playlist)
      xml = {:command=>"playlist", :playlist=>playlist.name}.to_xml(:root => "response")
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class Remove < WebRequest
    def call(env)
      puts "SpotiThin.Thin.Remove"
      rp = env["PATH_INFO"]
      puts "rp: #{rp}"
      index = rp.match(/^\/(.*)/)[1]
      puts "Index: " + index
      @playlist[index.to_i][:status] = "removed"
      xml = {:command=>"remove", :index=>index}.to_xml(:root => "response")
      [200, {'Content-Type'=>'text/xml'}, [xml]]
    end
  end

  class GetQueue < WebRequest
    def call(env)
      xml_array = []
      @trunk = 3
      if (@sp.index < @trunk)
        @trunk = @sp.index
      end
      list = @sp.playlist.drop(@sp.index-@trunk).take(20)
      puts list
      list.take(20).each do |item|
        xml_array.push({ :artist => item[:track].artist.name, :song => item[:track].name,
                         :album => item[:track].album.name, :status => item[:status],
                         :username => item[:username], :user_id => item[:user_id]})
      end
      xml = xml_array.to_xml(:root => "root").gsub(" <root", " <item").gsub(" </root", " </item")
      [200, {"Content-Type"=>"text/xml"}, [xml]]
    end
  end

  class Phone 
    def call(env)
      agent = env["HTTP_USER_AGENT"]
      html = File.open("web/clients/iphone5.html").read
      [200, {"Content-Type"=>"text/html"}, [html]]
    end
  end

  class GetFile
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

  class Register < WebLog
    def initialize (user_hash, priv_hash, char_map)
      @user_hash = user_hash
      @priv_hash = priv_hash
      @char_map = char_map
    end
    
    def call(env)
      log(env)
      rp = env["PATH_INFO"]
      username, device, key = rp.split("/")[1..-1]
      xml = {:command => self.class.to_s.split(":").last}
      if @priv_hash["clientkey"].empty? or @priv_hash["clientkey"] == key
        xml[:user_id] = (0...16).map{@char_map[rand(@char_map.length)]}.join      
        xml[:role] = "client"
        xml[:result] = "ok"
      end

      if @priv_hash["adminkey"] == key
        xml[:user_id] = (0...16).map{@char_map[rand(@char_map.length)]}.join      
        xml[:role] = "admin"
        xml[:result] = "ok"
      elsif xml[:result] != "ok"
        xml[:result] = "auth"
      end

      @user_hash[xml[:user_id]] = {username: username, device: device, role: xml[:role], time: Time.new} if xml[:result] == "ok"
      [200, {"Content-Type"=>"text/xml"}, [xml.to_xml(:root => "response")]]
    end
  end

  class IsReg
    def initialize (user_hash)
      @user_hash = user_hash
    end
    
    def call(env)
      rp = env["PATH_INFO"]
      uid = rp.split("/")[1..-1].first
      xml = {:command => self.class.to_s.split(":").last}
      if @user_hash[uid].nil?
        xml[:result] = "auth"
      else
        @user_hash[uid][:time] = Time.new
        xml[:result] = "ok"
      end
      [200, {"Content-Type"=>"text/xml"}, [xml.to_xml(:root => "response")]]
    end
  end

end
