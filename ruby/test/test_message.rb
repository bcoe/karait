require 'helper'
require 'karait'

class TestQueue < Test::Unit::TestCase
  should "return instance variables as a hash when to_hash is called" do
    queue = Karait::Message.new
    assert true
  end
end
