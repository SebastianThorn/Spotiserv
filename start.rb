#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require_relative "spotiplay.rb"
require_relative "spotithin.rb"


def prompt(string, options = {})
  print(string + ': ')
  $stdout.flush
  system("stty -echo") if options[:hide]
  gets.chomp
ensure
  if options[:hide]
    system("stty echo")
    puts
  end
end


# SETUP
port = 8001

spotify_username = prompt("Please enter your spotify username")
spotify_password = prompt("Please enter your spotify password", hide: true)


sp = SpotiPlay.new(spotify_username, spotify_password)
puts "Spotiplay.new done"

st = SpotiThin.new(port, sp.playlist, sp)
