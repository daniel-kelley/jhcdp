#
#  jhcdp.rb
#
#  Copyright (c) 2020 by Daniel Kelley
#
# https://www.quantamagazine.org/three-math-puzzles-inspired-by-john-horton-conway-20201015/
#
# Puzzle #1
#
# Failed to find it by hand. Where did I go wrong?
# The usual suspects: missed branches, accidental digit duplication
#

require 'set'
require 'pp'

class Node
  attr_reader :level
  attr_reader :label
  attr_reader :q
  attr_accessor :trivial
  attr_accessor :found
  attr_accessor :child
  attr_accessor :terminal

  @@idx = 1

  def initialize(level, q, found = false)
    @level = level
    @q = q
    @found = found
    @label = "#{q.num[-1]}_#{level}_#{@@idx}"
    @trivial = true
    @@idx += 1
    @child = []
  end

  def traverse_edge(&block)
    @child.each do |node|
      raise 'oops' if child == self
      if !trivial
        block.call(self, node)
        node.traverse_edge(&block)
      end
    end
  end

  def add_child(node)
    @child << node
  end

  def traverse_node(&block)
    block.call(self)
    @child.each do |node|
      node.traverse_node(&block)
    end
  end

  def desc
    s = q.num[-1].to_s
    s << "t" if trivial
    s
  end

  def found?
    @found
  end

  def trivial?
    @trivial
  end

  def terminal?
    @terminal
  end

end

class Q
  attr_reader :num
  def initialize(num, n, digits)
    @num = num.dup
    @num << n
    @digits = digits
  end

  def factor
    @num.length
  end

  def digit
    @num[-1]
  end

  def check(level,node)

    raise "oops" if factor != level

    #puts "Check #{show} % #{factor} #{@digits.inspect}"
    if value % factor == 0
      #puts "Maybe #{show} % #{factor}"
      digits = @digits.dup.delete(digit)
      if digits.empty?
        puts "Found #{show}"
        node.found=true
        node.trivial=false
      else
        digits.each do |n|
          q = Q.new(@num, n, digits)
          if !q.trivial?
            dnode = Node.new(level, q)
            node.add_child(dnode)
            q.check(level+1,dnode)
          #else
          #  puts "Trivial #{n} for #{q.factor} #{@num}"
          end
        end
      end
    else
      node.terminal = true
    end
    node.trivial = false
    false
  end

  def trivial?

    # Short circuit: the parity of the factor should be the
    # same as the parity of the number

    return true if factor.even? != value.even?

    case digit
    when 0
      # '0' is only expected as the last digit when the factor == 10
      return true if factor != 10
    when 5
      # digit '5' is only expected when the factor == 5
      return true if factor != 5
    end

    case factor
    when 3,6,9
      return true if (sum_digits % 3) != 0
    when 5
      # digit '5' is only expected when the factor == 5
      return true if digit != 5
    when 10
      # '0' is only expected as the last digit when the factor == 10
      return true if digit != 0
    end

    false
  end

  def value
    h = {} # check that digits are unique
    n = 0;
    f = 1;
    @num.reverse.each do |d|
      raise "oops" if !h[d].nil?
      n = n + d*f;
      f = f * 10;
      h[d]=1
    end
    n
  end

  def sum_digits
    s = 0
    @num.each { |n| s += n }
    s
  end

  def show
    s = ""
    @num.each { |n| s << n.to_s }
    s
  end
end
graph=ARGV[0]
node=[]
rc = nil
digits = Set[0,1,2,3,4,5,6,7,8,9]
digits.each do |n|
  q = Q.new([],n,digits.dup.delete(n))
  if !q.trivial?
    node[n] = Node.new(0,q)
    if q.check(1,node[n])
      rc = 1 if rc.nil?
    end
  end
end

if !graph.nil?
  File.open(graph, 'w') do |f|
    #f.puts node.inspect
    f.puts "strict digraph g {"
    node.each do |n|
      next if n.nil?
      next if n.trivial?
      # debug
      # next if n.q.digit != 3
      n.traverse_edge do |from,to|
        if from.trivial? || to.trivial?
          f.puts "# Trivial \"#{from.label}\"" if from.trivial?
          f.puts "# Trivial \"#{to.label}\"" if to.trivial?
        else
          f.puts "\"#{from.label}\" -> \"#{to.label}\""
        end
      end
      n.traverse_node do |nn|
        next if nn.trivial?
        attr = "label = \"#{nn.desc}\""
        attr << " shape = \"diamond\"" if nn.found
        f.puts "\"#{nn.label}\" [#{attr}]"
      end
    end
    f.puts "}"
  end
end

exit rc.nil?
