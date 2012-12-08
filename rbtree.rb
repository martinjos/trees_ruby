require 'printtree'

class NilClass
    def left
	self
    end
    def right
	self
    end
    def [](side)
	self
    end
    def red?
	false
    end
    def black?
	true
    end
    def <<(x)
	Node.new(x)
    end
    def size
	0
    end
    def check
	0
    end
    def pt(stack=[])
	PrintTree.indent(stack)
	puts "" # always black - no need to print colour
    end
    def clone
	self
    end
end

class Node
    attr :left, true
    attr :right, true
    attr :value

    def initialize(x)
	@value = x
	@red = true
	@left = nil
	@right = nil
    end

    def red?
	@red
    end

    def black?
	!@red
    end

    def red!
	@red = true
    end

    def black!
	@red = false
    end

    def []=(side, val)
	# [-1, 1].include?(side)
	if side < 0
	    @left = val
	else
	    @right = val
	end
    end

    def [](side)
	# [-1, 1].include?(side)
	if side < 0
	    @left
	else
	    @right
	end
    end

    # rotate side to the top
    def rot(side)
	# [-1, 1].include?(side)
	if side < 0
	    clock
	else
	    anti
	end
    end

    def clock
	head = @left
	@left = head.right
	head.right = self
	head
    end

    def anti
	head = @right
	@right = head.left
	head.left = self
	head
    end

    def add(x)
	side = x <=> @value
	if side == 0
	    @value = x
	    return self
	end
	self[side] = self[side] << x
	head = self
	if self.black?
	    if self[-side].black?
		known = false
		if self[side].red? and self[side][-side].red?
		    self[side] = self[side].rot(-side)
		    known = true
		end
		if known or (self[side].red? and self[side][side].red?)
		    self.red!
		    head = self.rot(side)
		    head.black!
		end
	    elsif self[side].red? and (self[side][side].red? or self[side][-side].red?)
		self.red!
		self[side].black!
		self[-side].black!
	    end
	end
	head
    end

    alias << add

    def delete(x)
	#puts "Node(#{@value}).delete"
	#pt
	side = x <=> @value
	head = self
	depth_change = false
	if side == 0
	    if @left.is_a?(Node)
		(@value, @left, child_depth_change) = @left.delete_last
		(head, depth_change) =
		    delete_balance(head, -1, child_depth_change)
	    elsif @right.is_a?(Node)
		# assert(self.black? && @right.red?)
		head = @right
		head.black!
	    else
		head = nil
		if black?
		    depth_change = true
		end
	    end
	elsif self[side].is_a?(Node)
	    (self[side], child_depth_change) = self[side].delete(x)
	    (head, depth_change) =
		delete_balance(head, side, child_depth_change)
	end
	[head, depth_change]
    end

    def delete_last
	#puts "Node(#{@value}).delete_last"
	#pt
	value = nil
	head = self
	depth_change = false
	if @right.is_a?(Node)
	    (value, @right, right_depth_change) = @right.delete_last
	    (head, depth_change) = delete_balance(head, 1, right_depth_change)
	elsif @left.is_a?(Node)
	    # assert(self.black? && @left.red?)
	    value = @value
	    head = @left
	    head.black!
	else
	    value = @value
	    head = nil
	    if black?
		depth_change = true
	    end
	end
	[value, head, depth_change]
    end

    def delete_balance(head, side, child_depth_change)
	depth_change = false
	if child_depth_change
	    #puts "Node(#{@value}).delete_balance"
	    #pt
	    # assert(head[side].black? && head[-side].depth >= 1)
	    if head[-side].black?
		if head[-side][side].black? &&
		   head[-side][-side].black?
		    head[-side].red!
		    if head.black?
			depth_change = true
		    else
			head.black!
		    end
		elsif head[-side][side].red? &&
		      head[-side][-side].red?
		    if head.black?
			head[-side] = head[-side].rot(side)
			head = head.rot(-side)
			head.black!
		    else
			head = head.rot(-side)
			head[side].black!
			head[-side].black!
			head.red!
		    end
		else
		    if head[-side][side].red?
			head[-side] = head[-side].rot(side)
			# N.B.: the necessary recolouring happens below
		    end
		    # assert(head[-side][-side].red?)
		    if head.black?
			head = head.rot(-side)
			head.black!
			head[side].red!
			head[-side].red!
			depth_change = true
		    else
			head = head.rot(-side)
			head.black!
			head[-side].red!
		    end
		end
	    end
	end
	[head, depth_change]
    end

    def size
	@left.size + @right.size + 1
    end

    def check
	lc = @left.check
	rc = @right.check
	if lc != rc
	    raise "Tree is not balanced"
	end
	if black?
	    lc + 1
	else
	    if @left.red? || @right.red?
		raise "Red node has red child"
	    end
	    lc
	end
    end
    
    def pt(stack=[])
	PrintTree.indent(stack)
	puts (@red ? "red" : "black") + " #{@value}"
	if !@left.nil? || !@right.nil?
	    @left.pt(stack + [true])
	    @right.pt(stack + [false])
	end
    end

    def to_s
	s = "#{@value}"
	if red?
	    s = "*" + s
	end
	if !@left.nil? || !@right.nil?
	    s += "(#{@left},#{@right})"
	end
	s
    end

    def clone
	c = self.dup
	c.left = @left.clone
	c.right = @right.clone
	c
    end

    def diff(other, stack=[], saved_stack=[nil])
	if @value != other.value ||
	   @red != other.red? ||
	   @left.nil? != other.left.nil? ||
	   @right.nil? != other.right.nil?
	    # there is some difference
	    #puts "Difference detected"
	    if saved_stack[0].nil?
		saved_stack[0] = stack.clone
	    else
		saved_stack[0] = saved_stack[0].lcd(stack)
	    end
	else
	    #puts "No difference here..."
	    if !@left.nil?
		@left.diff(other.left, stack + [-1], saved_stack)
	    end
	    if !@right.nil?
		@right.diff(other.right, stack + [1], saved_stack)
	    end
	end
	saved_stack
    end

    def walk_stack(stack)
	if stack.empty?
	    self
	else
	    self[stack.first].walk_stack(stack[1..-1])
	end
    end
end

class Array
    def lcd(other)
	each_with_index {|item, idx|
	    if idx >= other.size || other[idx] != item
		return slice(0, idx)
	    end
	}
	self
    end
end

class RBTree
    attr :head, true

    def initialize
	@head = nil
    end

    def add(x)
	@head = @head << x
	@head.black!
	self
    end

    alias << add

    def delete(x)
	(@head, depth_change) = @head.delete(x)
	self
    end

    def size
	@head.size
    end

    def check
	if @head.red?
	    raise "Head node is red"
	end
	@head.check
    end

    def pt
	@head.pt
    end

    def to_s
	"RBTree:#{@head.to_s}"
    end

    def clone
	c = self.dup
	c.head = @head.clone
	c
    end

    def diff(other)
	if @head.nil? != other.head.nil?
	    diff_result(@head, other.head)
	elsif !@head.nil?
	    stack = @head.diff(other.head)
	    stack = stack[0]
	    if stack.nil?
		puts "No difference."
	    else
		diff_result(@head.walk_stack(stack),
			    other.head.walk_stack(stack))
	    end
	else
	    puts "No difference."
	end
    end
end

def diff_result(x, y)
    puts "First:"
    x.pt
    puts "Second:"
    y.pt
end

class TreeTestError < RuntimeError
    attr :t, :ot
    def initialize(msg, t, ot)
	super(msg)
	@t = t
	@ot = ot
    end
end

def testadd(num, top, do_dump=true, t=RBTree.new)
    ot = nil
    begin
	(0...num).each {
	    t << rand(0...top)
	    t.check
	    ot = t
	}
    rescue RuntimeError => e
	puts "\n#{e}\n"
	raise TreeTestError.new(e.message, t, ot)
    end
    if do_dump
	t.pt
    end
    t
end

def testdelete(num, top, do_dump=true, t)
    ot = nil
    begin
	(0...num).each {
	    t.delete rand(0...top)
	    t.check
	    ot = t.clone
	}
    rescue RuntimeError => e
	puts "\n#{e}\n"
	raise TreeTestError.new(e.message, t, ot)
    end
    if do_dump
	t.pt
    end
    t
end

def testall(numtop, reps=100)
    top = 10000
    t = RBTree.new
    begin
	(0...reps).each {
	    r = rand(0...numtop)
	    puts "Adding #{r}"
	    testadd(r, top, false, t)
	    puts "t.size=#{t.size}, t.check=#{t.check}"

	    r = rand(0...numtop*4) # remove more, because some will miss
	    puts "Deleting #{r}"
	    testdelete(r, top, false, t)
	    puts "t.size=#{t.size}, t.check=#{t.check}"
	}
    rescue TreeTestError => e
	return e
    end
    t
end
