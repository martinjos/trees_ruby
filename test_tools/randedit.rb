#!/usr/bin/env ruby

#
# Usage:
#
#    randedit <number-of-chars>
#
# The default value for <number-of-chars> is 10,000
#

$: << '.'
require 'rope'
require 'curses'

display = true
if ARGV.size > 0 and ARGV[0] == "-n"
    ARGV.shift
    display = false
end

target = 10_000
if ARGV.size > 0
    target = ARGV[0].to_i
end

seed = Random.new_seed

if display
    Curses.init_screen
    Curses.clear
end

Random.srand(seed)
str = ""

tot_1 = 0
tot_2 = 0

(0...target).each {
    pos = Random.rand(0..str.size)
    char = Random.rand(32...126).chr
    time_1 = Time.now.to_f
    str = str[0...pos] + char + str[pos..-1]
    time_2 = Time.now.to_f
    tot_1 += time_2 - time_1
    if display
	Curses.setpos(0, 0)
	Curses.addstr(str)
	Curses.refresh
    end
}

if display
    Curses.clear
end

Random.srand(seed)
rope = ""

time_3 = Time.now.to_f

def curses_addrope(rope)
    Walker.new(rope).each{|str|
	Curses.addstr(str)
    }
end

(0...target).each {
    pos = Random.rand(0..rope.size)
    char = Random.rand(32...126).chr
    time_1 = Time.now.to_f
    rope = concat(concat(substr(rope, 0, pos), char), substr(rope, pos, rope.size))
    time_2 = Time.now.to_f
    tot_2 += time_2 - time_1
    if display
	Curses.setpos(0, 0)
	curses_addrope(rope)
	Curses.refresh
    end
}

if display
    Curses.close_screen
end

puts "With ordinary strings: took #{tot_1} seconds"
puts "With ropes: took #{tot_2} seconds"

# I don't know why I'm still getting nil appearing within the rope
equal = (str == Walker.new(rope).map{|str| str.nil? ? "" : str }.inject(&:+))

puts "Let's see if they're equal: #{equal}"
