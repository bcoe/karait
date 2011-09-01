require 'helper'
require 'karait'

class TestQueue < Test::Unit::TestCase
  should "initialize a capped collection when a queue is created" do
    queue = Karait::Queue.new
    assert true
  end
end
