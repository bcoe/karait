require 'helper'
require 'karait'
require 'yaml'

class TestMessage < Test::Unit::TestCase
  should "should add attribute accessors when initialized with a raw message" do
    message = Karait::Message.new(
      raw_message={
        :apple => 5,
        :banana => 3
      }
    )
    
    message.apple = 6
    assert_equal 6, message.apple
    assert_equal 3, message.banana
  end
  
  should "add new attribute accessors for missing methods" do
    message = Karait::Message.new(raw_message={
        :apple => 5,
        :banana => 3
    })
    message.foo = 9
    assert_equal 9, message.foo
  end
end
