#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require "hallon"
require "hallon-openal"

class SpotiPlay
  attr_accessor :player, :playlist

  def initialize (username, password)
    # Setting up variables
    playing = false
    #require_relative "login.rb"
    self.playlist = []

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
    hallon_appkey   = IO.read(appkey_path)

    # Make sure the credentials are there. We don’t want to go without them.
    if username.empty? or password.empty?
      abort <<-ERROR
    Sorry, you must supply both username and password for Hallon to be able to log in.

    You may also edit examples/common.rb by setting your username and password directly.
  ERROR
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

    session2 = Hallon::Session.instance
    self.player = Hallon::Player.new(Hallon::OpenAL)


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
  
  def add_to_playlist (item)
    self.playlist.push (item)
    "Added #{item[:track].name} to the playlist!"
    unless self.player.status == :playing
      p_play (self.playlist.first[:track])
    end
  end

end
