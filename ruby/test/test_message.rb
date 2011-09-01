require 'helper'
require 'karait'
require 'yaml'

class TestMessage < Test::Unit::TestCase
  
  def setup
    Mongo::Connection.new()['karait_test']['queue_test'].drop()
  end
  
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
  
  should "not copy blacklisted keys when to_hash called" do
      raw_message = {
          '_id' => 'foobar',
          '_meta' => {
              'foo' => 2
          }
      }
      message = Karait::Message.new(raw_message=raw_message)
      hash = message.to_hash
      
      assert_equal 0, hash.keys.count
  end
  
  should "set expired to true when delete is called on a message" do
      collection = Mongo::Connection.new()['karait_test']['queue_test']
      collection.insert({
          'routing_key' => 'foobar',
          'apple' => 3,
          'banana' => 5,
          '_meta' => {
              'timestamp' => 2523939,
              'expire' => 20393,
              'expired' => false
          }
      })
      raw_message = collection.find_one({'_meta.expired' => false})
      assert_equal 3, raw_message['apple']
      message = Karait::Message.new(raw_message=raw_message, queue_collection=collection)
      message.delete()
      assert_equal 0, collection.find({'_meta.expired' => false}).count
  end

  should "set expired to true if current time minus timestamp is greater than expire" do
    raw_message = {
        'routing_key' => 'foobar',
        'apple' => 3,
        'banana' => 5,
        '_meta' => {
            'timestamp' => 0,
            'expire' => 10,
            'expired' => false
        }
    }

    message = Karait::Message.new(raw_message=raw_message)
    assert_equal true, message.expired?
  end
  
  should "not set expired to true if expire is -1.0" do
    raw_message = {
        'routing_key' => 'foobar',
        'apple' => 3,
        'banana' => 5,
        '_meta' => {
            'timestamp' => 0,
            'expire' => -1.0,
            'expired' => false
        }
    }
    
    message = Karait::Message.new(raw_message=raw_message)
    assert_equal false, message.expired?
  end
  
end
