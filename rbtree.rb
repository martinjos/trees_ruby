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
	side = x <=> @value
	head = self
	depth_change = false
	if side == 0
	    if @left.is_a?(Node)
		(@value, head, child_depth_change) = @left.delete_last
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
	@left.pt(stack + [true])
	@right.pt(stack + [false])
    end
end

class RBTree
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
end

def testadd(num, top, do_dump=true, t=RBTree.new)
    (0...num).each {
	t << rand(0...top)
	t.check
    }
    if do_dump
	t.pt
    end
    t
end
