$: << File::dirname(File::expand_path(__FILE__))
require "HDLBranch"

bl = HDLBranch.new

puts bl.down_branch
