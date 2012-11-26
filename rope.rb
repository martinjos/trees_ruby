# Reference:
# Hans J. Boehm, Russ Atkinson, Michael Plass: "Ropes: An Alternative to
# Strings", Software--Practice and Experience, Vol 25(12), 1315-1330, Dec 1995
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

    def initialize(left, right)
	@left = left
	@right = right
    end

    def depth
	[@left.depth, @right.depth].max + 1
    end

    def size
	@left.size + @right.size
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
def rebalance(rope)
    walker = Walker.new(rope)
    list = []
    walker.each{|leaf|
	while !list.empty? && list[0].size < leaf.size
	    leftnode = list.slice!(0)
	    while !list.empty? && list[0].size < leaf.size
		leftnode = Concat.new(list.slice!(0), leftnode)
	    end
	    leaf = Concat.new(leftnode, leaf)
	end
	list.unshift leaf
    }
    list.inject {|a, b| Concat.new(b, a) }
end

$default_concat_copy_limit = 30

def concat(left, right, copy_limit = $default_concat_copy_limit)
    node = Concat.new(left, right)
    if !left.is_a?(Concat) && !right.is_a?(Concat) && left.size + right.size <= copy_limit
	left + right
    elsif !left.is_a?(Concat) && right.is_a?(Concat) &&
	  !right.left.is_a?(Concat) && left.size + right.left.size <= copy_limit
	Concat.new(left + right.left, right.right)
    elsif !right.is_a?(Concat) && left.is_a?(Concat) &&
          !left.right.is_a?(Concat) && right.size + left.right.size <= copy_limit
	Concat.new(left.left, left.right + right)
    elsif node.size < fib(node.depth + 2)
	puts "Rebalancing"
	rebalance(node)
    else
	node
    end
end
