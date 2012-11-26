module PrintTree

    def self.indent(stack)
        stack.each_with_index{|item, idx|
            print idx == stack.size - 1 ? " \\_ "
                : item ? " |  "
                : "    "
        }
    end

end
