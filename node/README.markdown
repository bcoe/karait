Karait
======

A ridiculously simple queuing system, with clients in various languages, built on top of MongoDB.

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

Copyright
---------

Copyright (c) 2011 Attachments.me. See LICENSE.txt for
further details.
