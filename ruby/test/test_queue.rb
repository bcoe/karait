require 'helper'
require 'mongo'
require 'karait'

class TestQueue < Test::Unit::TestCase
  
  def setup
    Mongo::Connection.new()['karait_test']['queue_test'].drop()
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
  
  should "attach to a mongo queue collection that already exists" do
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
  
  should "write a dictionary into the mongo queue collection" do
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
  
  should "write a message object into the mongo queue collection" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    message = Karait::Message.new
    message.apple = 5
    message.banana = {
      :foo => 2
    }
    queue.write message
    
    collection = Mongo::Connection.new()['karait_test']['queue_test']
    obj = collection.find_one
    assert_equal 5, obj['apple']
    assert_equal 2, obj['banana']['foo']
  end

  should "read a message object from the mongo queue collection" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
  
    write_message = Karait::Message.new
    write_message.apple = 5
    write_message.banana = 6
    write_message.inner_object = {
      'foo' => 1,
      'bar' => 2
    }
    queue.write write_message
  
    read_message = queue.read()[0]
    assert_equal 5, read_message.apple
    assert_equal 2, read_message.inner_object['bar']
    assert_equal 3, read_message.to_hash.keys.count
  end
  
  should "return messages in fifo order" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write Karait::Message.new({'foo' => 1})
    queue.write Karait::Message.new({:foo => 2})
    queue.write Karait::Message.new({'foo' => 3})
    messages = queue.read()
    
    assert_equal 1, messages[0].foo
    assert_equal 2, messages[1].foo
    assert_equal 3, messages[2].foo
  end
  
  should "only return messages with the appropriate routing key when it's provided" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write(Karait::Message.new({:foo => 1}), :routing_key => 'foobar')
    queue.write Karait::Message.new({:foo => 2})

    messages = queue.read(:routing_key => 'foobar')
    assert_equal 1, messages.count
    assert_equal 1, messages[0].foo
  end
  
  should "only return messages with no routing key when none is provided" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write(Karait::Message.new({:foo => 1}), :routing_key => 'foobar')
    queue.write Karait::Message.new({:foo => 2})
    
    messages = queue.read()
    assert_equal 1, messages.count
    assert_equal 2, messages[0].foo
  end
  
  should "should no longer return a message when delete is called on it" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write Karait::Message.new({:foo => 1})
    messages = queue.read()
    assert_equal 1, messages.count
    assert_equal 1, messages[0].foo
    
    messages[0].delete
    messages = queue.read()
    assert_equal 0, messages.count
  end

  should "not remove message immediately with expire set" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write(Karait::Message.new({:foo => 1}), :expire => 0.5)
    sleep(0.1)
    messages = queue.read()
    assert_equal 1, messages.count
  end
  
  should "remove message once expire time is passed" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write(Karait::Message.new({:foo => 1}), :expire => 0.1)
    sleep(0.2)
    messages = queue.read()
    assert_equal 0, messages.count
    
    # Make sure the meta._expired key is actually set.
    collection = Mongo::Connection.new()['karait_test']['queue_test']
    raw_message = collection.find_one
    assert_equal true, raw_message['_meta']['expired']
  end
  
  
  should "remove all messages in array when delete messages called" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write Karait::Message.new({'foo' => 1})
    queue.write Karait::Message.new({:foo => 2})
    queue.write Karait::Message.new({'foo' => 3})
    messages = queue.read()
    queue.delete_messages messages
    messages = queue.read()
    assert_equal 0, messages.count
  end
  
  should "not see message in queue again until visibility timeout has passed" do
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.write Karait::Message.new({'foo' => 1})
    queue.write Karait::Message.new({:foo => 2})
    queue.write Karait::Message.new({'foo' => 3})
    messages = queue.read(:visibility_timeout => 0.4)
    assert_equal 3, messages.count
    messages = queue.read(:visibility_timeout => 0.4)
    assert_equal 0, messages.count
    sleep(0.5)
    messages = queue.read(:visibility_timeout => 0.4)
    assert_equal 3, messages.count
  end
  
  should "block on reading from queue until polling timeout reached" do
    start_time = Time.new.to_f
    
    queue = Karait::Queue.new(
      :database => 'karait_test',
      :queue => 'queue_test'
    )
    
    queue.read( :block => true, :polling_timeout => 0.1 )
    queue.write Karait::Message.new({'foo' => 1})
    messages = queue.read( :block => true, :polling_timeout => 0.1 )

    assert_equal 1, messages.count
    stop_time = Time.new.to_f
    assert_equal true, stop_time - start_time > 0.1
  end
end
