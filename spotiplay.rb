#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require "hallon"
require "hallon-openal"

class SpotiPlay
  attr_accessor :player, :playlist, :playing, :external_playlist, :local_playlist

  def initialize (username, password)
    # Setting up variables
    self.playing = false
    self.playlist = []
    self.local_playlist = Time.new.strftime('%Y-%m-%d.txt')
    self.external_playlist = nil
    
    # This is a quick sanity check, to make sure we have all the necessities in order.
    appkey_path = File.expand_path('./spotify_appkey.key')
    unless File.exists?(appkey_path)
      abort <<-ERROR
    Your Spotify application key could not be found at the path:
      #{appkey_path}

    Please adjust the path in examples/common.rb or put your application key in:
      #{appkey_path}

    You may download your application key from:
      https://developer.spotify.com/en/libspotify/application-key/
      ERROR
    end
    hallon_appkey = IO.read(appkey_path)
    
    # Make sure the credentials are there. We don’t want to go without them.
    if username.empty? or password.empty?
      abort "Sorry, you must supply both username and password for Hallon to be able to log in."
    end
    
    session = Hallon::Session.initialize(hallon_appkey) do
      on(:log_message) do |message|
        puts "[LOG] #{message}"
      end
      
      on(:credentials_blob_updated) do |blob|
        puts "[BLOB] #{blob}"
      end
      
      on(:connection_error) do |error|
        Hallon::Error.maybe_raise(error)
      end
      
      on(:logged_out) do
        abort "[FAIL] Logged out!"
      end
    end
    session.login!(username, password)
    
    self.player = Hallon::Player.new(Hallon::OpenAL)
  end

  #TODO: INFO, Remove console output
  def p_play (track)
    Thread.new {
      puts "Playing: #{track.name} by #{track.artist.name}"
      self.player.play!(track)
      puts "Song ended: #{track.name} by #{track.artist.name}"
      self.playlist.shift
      if self.playlist.empty?
        puts "No more songs in playlist, trying to open external playlist"
        unless self.external_playlist.nil?
          puts "No more songs in playlist, playing random song from external playlist"
          self.p_play (self.external_playlist.tracks[rand(self.external_playlist.tracks.size)])
        else
          puts "else"
        end
        self.player.stop
      else
        puts "Starting nex song"
        self.p_play (self.playlist.first[:track])
      end
    }
  end

  # Play the next song in the playlist
  def p_next
    unless self.playlist.empty?
      if self.playing
        puts "Next song"
        self.playlist.shift
        self.p_play (self.playlist.first[:track])
      else
        puts "player is not playing a song right now, starting playback"
        self.playing = true
        p_next
      end
    else
      "no tracks in playlist, add some please"
    end
  end

  def set_playlist (playlist = null)
    puts "Spotithin.set_playlist"
    if playlist
      self.playing = true
      self.external_playlist = playlist
      self.p_play (self.external_playlist.tracks[rand(self.external_playlist.tracks.size)])
    else
      self.playing = false
    end
  end

  def p_pause
    self.player.pause
  end

  def p_resume
    self.player.play
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
  
  # Adds a track to the current playlist, takes a hash. {:track=>Hallon::Track, :user=>String}
  def add_to_playlist (item)
    self.playlist.push (item)
    "Added #{item[:track].name} to the playlist!"
    File.open("tmp/" + self.local_playlist, "a") do |f|
      f.write (item[:track].name + " - " +  item[:track].artist.name + "\n")
    end
    unless self.player.status == :playing
      self.p_play (self.playlist.first[:track])
    end
  end

end
