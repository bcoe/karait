require 'helper'
require 'mongo'
require 'karait'

class TestQueue < Test::Unit::TestCase
  
  def setup
    Mongo::Connection.new()['karait_test']['queue_test'].drop()
  end
  
  should "initialize queue with parameters" do
    queue = Karait::Queue.new :average_message_size => 20
    assert_equal 20, queue.average_message_size
    
    queue = Karait::Queue.new
    assert_equal 8192, queue.average_message_size
  end
  
  should "initialize a capped collection when a queue is created" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test',
      :average_message_size => 8192,
      :queue_size => 4096
    )
    
    options = Mongo::Connection.new()['karait_test']['queue_test'].options
    
    assert_equal true, options['capped']
    assert_equal 4096, options['max']
    assert_equal (8192 * 4096), options['size']
  end
  
  should "attach to a MongoDB collection that already exists" do
    collection = Mongo::Connection.new()['karait_test']['queue_test']
    collection.insert({
            :message => {
                :apple => 3,
                :banana => 5
            },
            :_meta => {
              :timestamp => 2523939,
              :expire => 20393,
              :routing_key => 'foo_key'
            }
    })
    assert_equal 1, collection.count()
    
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )

    collection = Mongo::Connection.new()['karait_test']['queue_test']
    assert_equal 1, collection.count()
    assert_equal nil, collection.options()
  end
  
  should "should write a dictionary into the MongoDB queue" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test',
      :average_message_size => 8192,
      :queue_size => 4096
    )
    
    queue.write({
        :apple => 5,
        :banana => 6,
        :inner_object => {
            :foo => 1,
            :bar => 2
        }
    })

    collection = Mongo::Connection.new()['karait_test']['queue_test']
    obj = collection.find_one()
    assert_equal 6, obj['banana']
    assert_equal 2, obj['inner_object']['bar']
    assert obj['_meta']['expire']
    assert obj['_meta']['timestamp']
  end
  
end
