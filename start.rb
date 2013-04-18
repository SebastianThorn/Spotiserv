#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# Requirements
require_relative "spotiplay.rb"
require_relative "spotithin.rb"
require "pry"

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

# Setup user-variables
if ARGV[0] then spotify_username = ARGV[0] else spotify_username = prompt("Please enter your spotify username") end
if ARGV[1] then spotify_password = ARGV[1] else spotify_password = prompt("Please enter your spotify password", hide: true) end

# Start player-server
sp = SpotiPlay.new(spotify_username, spotify_password)
puts "Spotiplay.new done"

# Start web-sever
st = SpotiThin.new(ip, port, sp)
