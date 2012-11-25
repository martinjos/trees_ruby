class NullNode
    def initialize(fsize, hfsize, compar)
    end

    def add(value)
	Node.new(fsize, hfsize, compar, [self, value, self])
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
	if idx % 2 != 0
	    self[idx] = value
	    return self
	end
	self.insert idx, *self.delete_at(idx).add(value)
	if self.size > @fsize
	    mid = self.size / 2
	    mid -= 1 if mid % 2 == 0
	    newright = Node.new(fsize, hfsize, compar, self.slice!(mid+1, self.size-mid-1))
	    Node.new(fsize, hfsize, compar, [self, self.slice!(mid), newright])
	end
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
	@head = @head.add(value)
    end
end
