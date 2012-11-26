# Reference:
# Hans J. Boehm, Russ Atkinson, Michael Plass: "Ropes: An Alternative to
# Strings", Software--Practice and Experience, Vol 25(12), 1315-1330, Dec 1995
#
# My modifications:
# * Efficient concatenation at both ends (not just on the right).
# * Substring that just returns an existing whole node if it can, or part of a
# single node, and never inserts empty nodes. (If necessary, it returns a
# single empty node.)
#

class String
    def depth
	0
    end
end

def fib(x)
    y = 0
    z = 1
    (2..x).each{
	tz = z
	z += y
	y = tz
    }
    z
end

class Concat
    attr :left
    attr :right
    attr :size

    def initialize(left, right)
	@left = left
	@right = right
	@size = left.size + right.size
    end

    def depth
	[@left.depth, @right.depth].max + 1
    end

    def to_s
	"(#{@left.inspect} + #{@right.inspect})"
    end
end

class Walker
    include Enumerable

    def initialize(rope)
	@rope = rope
	@stack = nil # ready to start
    end

    def next
	if @stack.nil?
	    @stack = []
	    r = @rope
	else
	    while !@stack.empty? and @stack[0][0] == 1
		@stack.shift
	    end
	    if @stack.empty?
		@stack = nil
		raise StopIteration
	    end
	    @stack[0][0] = 1
	    r = @stack[0][1].right
	end

	while r.is_a? Concat
	    @stack.unshift [0, r]
	    r = r.left
	end
	r
    end

    def each
	begin
	    while true
		yield self.next
	    end
	rescue
	end
    end
end

# this is a lot like shift-reduce...
# not accounting for empty nodes at the moment...
def rebalance(rope, copy_limit)
    walker = Walker.new(rope)
    list = []
    walker.each{|leaf|
	while !list.empty? && list[0].size <= leaf.size
	    leftnode = list.slice!(0)
	    while !list.empty? && list[0].size < leaf.size
		leftnode = concat(list.slice!(0), leftnode, copy_limit, false)
	    end
	    leaf = concat(leftnode, leaf, copy_limit, false)
	end
	list.unshift leaf
    }
    list.inject {|b, a| concat(a, b, copy_limit, false) }
end

$default_concat_copy_limit = 30

def concat(left, right, copy_limit = $default_concat_copy_limit, rebalance=true)
    node = Concat.new(left, right)
    if !left.is_a?(Concat) && !right.is_a?(Concat) && left.size + right.size <= copy_limit
	left + right
    elsif !left.is_a?(Concat) && right.is_a?(Concat) &&
	  !right.left.is_a?(Concat) && left.size + right.left.size <= copy_limit
	Concat.new(left + right.left, right.right)
    elsif !right.is_a?(Concat) && left.is_a?(Concat) &&
          !left.right.is_a?(Concat) && right.size + left.right.size <= copy_limit
	Concat.new(left.left, left.right + right)
    elsif node.size < fib(node.depth + 2) and rebalance
	puts "Rebalancing"
	rebalance(node, copy_limit)
    else
	node
    end
end

# empty nodes are just nil for now.
# also, no lazy evaluation yet.
def substr(rope, start, finish)
    if !rope.is_a? Concat
	return rope[[0, start].max...finish]
    end

    # empty node
    return nil if finish <= start

    nodes = []
    lsize = rope.left.size
    fullsize = rope.size

    if start <= 0 && finish >= lsize
	nodes << rope.left
    elsif (start >= 0 && start < lsize) ||
	  (finish > 0 && finish <= lsize)
	nodes << substr(rope.left, start, finish)
    end

    if start <= lsize && finish >= fullsize
	nodes << rope.right
    elsif (start >= lsize && start < fullsize) ||
	  (finish > lsize && finish <= fullsize)
	nodes << substr(rope.right, start-lsize, finish-lsize)
    end

    if nodes.size == 1
	nodes[0]
    elsif nodes.size == 2
	if nodes[0].equal?(rope.left) && nodes[1].equal?(rope.right)
	    rope
	else
	    Concat.new(nodes[0], nodes[1])
	end
    else
	# empty node
	nil
    end
end
