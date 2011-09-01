Karait
======

A ridiculously simple queuing system, with clients in various languages, built on top of MongoDB.

The Problem?
------------
The company I work for (http://attachments.me) faced a conundrum. SQS was not quite cutting it for some of our messaging queue needs, but I wanted to avoid immediately pulling a new technology, .e.g., Redis or RabitMQ. Why? we don't make heavy use of a messaging queue, it's mainly for system-wide messaging, e.g., a global shutdown message before deploying new code.

The solution? 
-------------

We already had MongoDB in the stack, and it was globally accessible. I'd heard of other people building queues on top of capped collections (http://www.captaincodeman.com/2011/05/28/simple-service-bus-message-queue-mongodb/) and thought I'd give this a shot.

Enter Karait
------------

Karait is a simple queuing library built on top of capped collections in MongoDB. Currently it supports two types of messages:

* _Routed_ messages which you read and write with a specific routing key.
* _Broadcast_ messages which have no routing key.

Like Memcached, an expire can be set on a message which will cause it to be removed from the queue after a set number of seconds.

Built in Multiple Languages
---------------------------

We're a multi-language shop (currently, Python and Ruby). Messaging queues are a great way to allow code written in multiple languages to interoperate.

Keeping this in mind, I'm writing the Karait API in multiple languages (Ruby and Python so far)

Usage
=====

Ruby
----

_Writing to a queue_

```ruby
require 'karait'

queue = Karait::Queue.new(
    :host => 'localhost', # MongoDB host. Defaults to localhost.
    :port => 27017, # MongoDB port. Defaults to 27017.
    :database => 'karait', # Database that will store the karait queue. Defaults to karait.
    :queue => 'messages', # The capped collection that karait writes to. Defaults to messages.
    :average_message_size => 8192, # How big do you expect the messages will be in bytes? Defaults to 8192.
    :queue_size => 4096 # How many messages should be allowed in the queue. Defaults to 4096.
)

queue.write({
	:name => 'Benjamin',
	:action => 'Rock'
})

# or

message = Karait::Message.new
message.name = 'Benjamin'
message.action = 'Rock!'

queue.write(message, :routing_key => 'my_routing_key', :expire => 3.0)
```

_Reading from a queue_

```ruby
require 'karait'

queue = Karait::Queue.new

message = queue.read().first
print "#{message.name}"

message.delete

# or

message = queue.read(:routing_key => 'my_routing_key').first
print "#{message.action}"

message.delete
```

See unit tests for more documentation.

Python
------

_Writing to a queue_

```python
from karait import Message, Queue

queue = Queue(
    host='localhost', # MongoDB host. Defaults to localhost.
    port=27017, # MongoDB port. Defaults to 27017.
    database='karait', # Database that will store the karait queue. Defaults to karait.
    queue='messages', # The capped collection that karait writes to. Defaults to messages.
    average_message_size=8192, # How big do you expect the messages will be in bytes? Defaults to 8192.
    queue_size=4096 # How many messages should be allowed in the queue. Defaults to 4096.
)

queue.write({
	'name': 'Benjamin',
	'action': 'Rock'
})

# or

message = Message()
message.name = 'Benjamin'
message.action = 'Rock!'

queue.write(message, routing_key='my_routing_key', expire=3.0)
```

_Reading from a queue_

```python
from karait import Message, Queue

queue = Queue()

message = queue.read()[0]
print "%s" % (message.name)

message.delete()

# or

message = queue.read(routing_key='my_routing_key')[0]
print "%s" % (message.action)

message.delete()
```

See unit tests for more documentation.

Atomic Operations
-----------------
An optional *visibility_timeout* can be set to allow for atomic operations on the same queue:

```ruby
require 'karait'

queue = Karait::Queue.new

message = queue.read(:routing_key='foobar', :visibility_timeout=3.0).first
print "#{message.name}"
message.delete
```

Examples
--------

See the examples folder for some scripts that read and write to queues.

Contributing to karait
----------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011 Attachments.me. See LICENSE.txt for
further details.
