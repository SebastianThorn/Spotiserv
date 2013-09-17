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

# Setup connection-variables
ip = Socket.ip_address_list[1].ip_address
port = 8001

# Read config-file
unless ARGV[0]
  puts "missing config-file, exiting"
  exit
end
config = ParseConfig.new(ARGV[0])
spotify_username = config["username"]
spotify_password = config["password"]

# Setup variables
spotify_username = prompt("Please enter your spotify username") if spotify_username.empty?
spotify_password = prompt("Please enter your spotify password", hide: true) if spotify_password.empty?
spotify_territory = Geocoder.search(open("http://whatismyip.akamai.com").read)[0].country_code

# Start player-server
sp = SpotiPlay.new(spotify_username, spotify_password)
puts "Territorry: #{spotify_territory}"
puts "Spotiplay.new done"

# Start web-sever
st = SpotiThin.new(ip, port, sp)
