#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# Requirements
require_relative "spotiplay.rb"
require_relative "spotithin.rb"
require "parseconfig"
require "geocoder"
require "open-uri"

# Snippet for fancy-printing
def prompt(string, options = {})
  print(string + ': ')
  $stdout.flush
  system("stty -echo") if options[:hide]
  STDIN.gets.chomp
ensure
  if options[:hide]
    system("stty echo")
    puts
  end
end

# Read config-file
unless ARGV[0] then puts "missing config-file, exiting"; exit end
config = ParseConfig.new(ARGV[0])

# Setup variables
ip = Socket.ip_address_list[1].ip_address
port = config["port"]
priv_hash = Hash.new
priv = %w[AddTrack next-track add-album set-playlist remove-track]
["clientkey", "adminkey"].each {|cmd| priv_hash[cmd] = config[cmd]}
priv.each {|cmd| if config[cmd] == "admin" then priv_hash[cmd] = 1 elsif config[cmd] == "client" then priv_hash[cmd] = 0 end}
spotify_username = config["username"]
spotify_password = config["password"]
spotify_username = prompt("Please enter your spotify username") if spotify_username.empty?
spotify_password = prompt("Please enter your spotify password", hide: true) if spotify_password.empty?
begin
  spotify_territory = Geocoder.search(open("http://whatismyip.akamai.com").read)[0].country_code
rescue SocketError => ex
  abort "[LOG] #{Time.new.strftime "[%d/%b/%Y %H:%M:%S.%L]"} E [#{ex.class}] Can not find a connection to the internet."
end
user_hash = Hash.new
play_server = SpotiPlay.new(spotify_username, spotify_password)

# Start fork to check if user is still active, remove user if inactive
Thread.new {
  loop do
    del = []
    user_hash.each do |user_id, user_data|
      if user_data[:time] < (Time.new - 15.minute)
        del.push(user_id)
      end
    end
    for user_id in del

      for track in play_server.playlist
        if track[:user_id] == user_id
          track[:user_id] = "false"
        end
      end

      user_hash.delete(user_id)

    end
    sleep 30
    #user_hash.delete_if {|user_id, user_data| user_data[:time] < (Time.new - 1.minute)}; sleep 10 # set 10min/60sec 
  end
}

# Start servers

web_erver = SpotiThin.new(ip, port, play_server, priv_hash, user_hash)
