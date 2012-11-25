class NullNode
    def initialize(fsize, hfsize, compar)
	@fsize = fsize
	@hfsize = hfsize
	@compar = compar
    end

    def add(value)
	[ true, Node.new(@fsize, @hfsize, @compar, [self, value, self]) ]
    end

    def remove(value)
	self
    end

    def dump(stack)
	# do nothing
    end

    def to_s
	"null"
    end

    def check
	# depth is 0
	0
    end

    def tree_count
	0
    end
end

class Node < Array
    def initialize(fsize, hfsize, compar, values)
	@fsize = fsize
	@hfsize = hfsize
	@compar = compar
	super(values)
    end

    # quick search because sorted
    def index(value, first=1, last = self.size - 2)
	mid = (first + last) / 2
	mid -= 1 if mid % 2 == 0
	return 0 if mid < 0
	side = @compar.call(value, self[mid])
	return mid if side == 0
	if side > 0
	    return last+1 if mid == last
	    index(value, mid + 2, last)
	else
	    return first-1 if mid == first
	    index(value, first, mid - 2)
	end
    end

    def add(value)
	idx = self.index(value)
	if idx % 2 == 1
	    self[idx] = value
	    return [ false, self ]
	end
	(did_split, sub_result) = self[idx].add(value)
	if did_split
	    self.delete_at(idx)
	    self.insert idx, *sub_result
	else
	    self[idx] = sub_result
	end
	if self.size > @fsize
	    mid = self.size / 2
	    mid -= 1 if mid % 2 == 0
	    newright = Node.new(@fsize, @hfsize, @compar, self.slice!(mid+1, self.size-mid-1))
	    [ true, Node.new(@fsize, @hfsize, @compar, [self, self.slice!(mid), newright]) ]
	else
	    [ false, self ]
	end
    end

    def remove(value=nil)
	idx = self.index(value)
	if idx % 2 == 0
	    self[idx].remove value
	    if idx == 0
		midx = 0
	    else
		midx = idx - 2
	    end
	elsif self[0].is_a? NullNode
	    self.slice! idx, 2
	else
	    self[idx] = self[idx + 1].remove_first
	    midx = idx - 1
	end

	# there are two cases: removed from here, and "removed" from null node
	if !self[0].is_a? NullNode
	    self.insert midx, *self.merge(self.slice!(midx, 3))
	end
    end

    def remove_first
	if self[0].is_a? NullNode
	    first = self[1]
	    self.slice!(0, 2)
	else
	    first = self[0].remove_first
	    self.insert 0, *self.merge(self.slice!(0, 3))
	end
	first
    end

    def merge((a, b, c))
	# a or c can be at most 2 (i.e 1 full segment) less than #{hfsize}
	# if either is larger than hfsize, it will be greater in units of 2
	# (i.e. whole segments)

	#puts "Merging with a.size=#{a.size}, c.size=#{c.size}, @hfsize=#{@hfsize}"
	#puts "a:"
	#a.dump
	#puts "b: #{b}"
	#puts "c:"
	#c.dump

	if a.size < @hfsize && c.size > @hfsize
	    a << b
	    a << c[0]
	    b = c[1]
	    c.slice! 0, 2
	elsif a.size > @hfsize && c.size < @hfsize
	    c.unshift b
	    c.unshift a[-1]
	    b = a[-2]
	    a.slice! -2, 2
	elsif (a.size <=> @hfsize) + (c.size <=> @hfsize) < 0
	    return [Node.new(@fsize, @hfsize, @compar, a + [b] + c)]
	end
	[a, b, c]
    end

    def indent(stack)
	stack.each_with_index{|item, idx|
	    print idx == stack.size - 1 ? " \\_ "
		: item ? " |  "
		: "    "
	}
    end

    def dump(stack=[])
	indent(stack)
	self.each_with_index{|item, idx|
	    if idx % 2 == 1
		print item.to_s + " "
	    end
	}
	print "\n"
	self.each_with_index{|item, idx|
	    if idx % 2 == 0
		item.dump(stack + [idx < self.size - 1 ? true : false])
	    end
	}
    end

    def check
	if self.size % 2 == 0
	    raise "Node size is even"
	end
	if self.size < @hfsize
	    raise "Node is too small"
	end
	if self.size > @fsize
	    raise "Node is too large"
	end
	depth = self[0].check
	self.each_with_index {|item, idx|
	    if idx % 2 == 0 and (!item.is_a?(Node) && !item.is_a?(NullNode))
		raise "Even child is not a Node"
	    end
	    if idx % 2 == 1 and (item.is_a?(Node) || item.is_a?(NullNode))
		raise "Odd child is a Node"
	    end
	    if idx % 2 == 0
		# Node or NullNode
		if idx != 0
		    if depth != item.check
			raise "Tree is not balanced"
		    end
		end
	    end
	}
	depth + 1
    end

    def tree_count
	s = 0
	self.each_with_index{|item, idx|
	    if idx % 2 == 0
		s += item.tree_count
	    else
		s += 1
	    end
	}
	s
    end
end

class BTree
    def initialize(size = 3, compar = ->(a,b){a <=> b})
	raise "size=#{size} is not an odd number >= 3" if size % 2 != 1 || size < 3
	@size = size
	@compar = compar
	vsize = size - 1
	hvsize = vsize / 2
	hsize = hvsize + 1
	fsize = size + vsize
	hfsize = hsize + hvsize
	@head = NullNode.new(fsize, hfsize, compar)
    end

    def add(value)
	(did_split, @head) = @head.add(value)
    end

    def remove(value)
	@head.remove(value)
	# empty. not strictly necessary, but restores initial state
	if @head.size == 1
	    @head = @head[0]
	end
    end

    def dump
	@head.dump
    end

    def check
	@head.check
    end

    def size
	@head.tree_count
    end
end

def bmap(size = 3, compar = ->(a,b){a <=> b})
    BTree.new(size, ->(a,b){ compar.call(a[0], b[0]) })
end

# add #{num} random integers in [ 0, #{top} ) to a ( #{order-1}, #{order} )
# B-tree and dump in "ps f" format
#
def testadd(order, num, top, do_dump=true)
    if order.is_a? BTree
	t = order
    else
	t = BTree.new(order)
    end

    (0...num).each{
	#puts "Adding a random integer..."
	t.add rand(0...top)
    }
    if do_dump
	t.dump
    end
    t
end

def testremove(t, num, top, do_dump=true)
    (0...num).each{
	#puts "Removing a random integer..."
	t.remove rand(0...top)
    }
    if do_dump
	t.dump
    end
    t
end

def testall(order, numtop, reps=100)
    top = 10000
    t = BTree.new(order)
    begin
	(0...reps).each {
	    r = rand(0...numtop)
	    puts "Adding #{r}"
	    testadd(t, r, top, false)
	    puts "t.size=#{t.size}, t.check=#{t.check}"

	    r = rand(0...numtop*4) # remove more, because some will miss
	    puts "Removing #{r}"
	    testremove(t, r, top, false)
	    puts "t.size=#{t.size}, t.check=#{t.check}"
	}
    ensure
	#puts "Ensuring we get a tree dump..."
	#t.dump
    end
    t
end
