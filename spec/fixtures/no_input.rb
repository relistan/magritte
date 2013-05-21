#!/usr/bin/env ruby

# Script to simulate a command that has closed its stdin.

$stdin.close
puts "one line"
puts "two lines"
puts "three lines"
sleep 0.1
