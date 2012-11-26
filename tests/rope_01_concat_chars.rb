#!/usr/bin/env ruby

require 'rbtest_common'
require 'rope'

r = "a"
(0..400).each { r = concat(r, "a") }

assert(fib(r.depth + 2) <= r.size)
