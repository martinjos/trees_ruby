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
    def pt(stack=[])
	PrintTree.indent(stack)
	puts "" # always black - no need to print colour
    end
end

class Node
    attr :left, true
    attr :right, true
    def initialize(x)
	@x = x
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
    def <<(x)
	side = x <=> @x
	if side == 0
	    @x = x
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
    def pt(stack=[])
	PrintTree.indent(stack)
	puts (@red ? "red" : "black") + " #{@x}"
	@left.pt(stack + [true])
	@right.pt(stack + [false])
    end
end

class RBTree
    def initialize
	@head = nil
    end
    def <<(x)
	@head = @head << x
	@head.black!
	self
    end
    def pt
	@head.pt
    end
end
