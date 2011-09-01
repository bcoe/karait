Karait
======

A ridiculously simple cross-language queuing system, built on top of MongoDB.

Contributing to karait
----------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Usage
-----

_Writing to a queue_

```ruby
require 'karait'
queue = Karait::Queue.new(
    :host => 'localhost', # MongoDB host. Defaults to _localhost_.
    :port => 27017, # MongoDB port. Defaults to _27017_.
    :database => 'karait', # Database that will store the karait queue. Defaults to _karait_.
    :queue => 'messages', # The capped collection that karait writes to. Defaults to _messages_.
    :average_message_size => 8192, # How big do you expect the messages will be in bytes? Defaults to _8192_.
    :queue_size => 4096 # How many messages should be allowed in the queue. Defaults to _4096_.
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
queue = Karait::Queue.new()
message = queue.read().first()
print "#{message.name}"
message.delete

# or

message = queue.read(:routing_key => 'my_routing_key')
print "#{message.action}"
message.delete
```

See unit tests for more documentation.

Copyright
---------

Copyright (c) 2011 bcoe. See LICENSE.txt for
further details.
