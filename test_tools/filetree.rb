#!/usr/bin/env ruby

$: << '.'
require 'rope'

def randfiletree(filename)
    r = ""
    File.open(filename) {|fh|
	fh.lines {|line|
	    r = concat(r, line)
	}
    }
    r.pt
end

if __FILE__ == $0

randfiletree(ARGV[0])

end # __FILE__ == $0
