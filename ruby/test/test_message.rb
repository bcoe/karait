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
    message = Karait::Message.new
    message.foo = 9
    assert_equal 9, message.foo
  end
  
  should "return a hash of appropriate instance variables when to_hash is called" do
    message = Karait::Message.new(
      raw_message={
        :apple => 5,
        :banana => 3
      }
    )
    message.apple = 6
    message.foo = {'bar' => 9}
    message.bar = [27]
    
    hash = message.to_hash
    
    assert_equal 6, hash['apple']
    assert_equal 3, hash['banana']
    assert_equal 9, hash['foo']['bar']
    assert_equal 27, hash['bar'][0]
    assert_equal 4, hash.keys.count
  end
end
