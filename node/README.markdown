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

```javascript
var puts = require('sys').puts,
    Queue = require('karait').Queue;

puts("Starting javascript writer.")

messagesWritten = 0.0
startTime = (new Date()).getTime() / 1000.0;

new Queue(function(err, queue) {
    if (err) {
        throw err;
    }
    
    (function writeMessage() {
        queue.write(
            {
                messages_written: messagesWritten,
                sender: 'writer.js',
                started_running: startTime,
                messages_written_per_second: messagesWritten / ( ( (new Date()).getTime() / 1000.0 ) - startTime )
            },
            {
                routingKey: 'for_reader'
            },
            function() {
                writeMessage();
            }
        )
        messagesWritten += 1;
    })();
});
```

_Reading from a queue_

```javascript
var puts = require('sys').puts,
    Queue = require('karait').Queue;

puts("Starting javascript reader.")

messagesRead = 0.0
startTime = (new Date()).getTime() / 1000.0;

new Queue(function(err, queue) {
    if (err) {
        throw err;
    }
    
    (function readMessages() {
        queue.read({routingKey: 'for_reader'}, function(err, messages) {
            for (var i = 0, message; (message = messages[i]) != null; i++) {
                messagesRead += 1;
                message.messages_read = messagesRead;
                message.messages_read_per_second = messagesRead / ( ( (new Date()).getTime() / 1000.0 ) - startTime );
                
                if (messagesRead % 250 == 0) {
                    puts(JSON.stringify(message.toObject()));
                }
            }
            queue.deleteMessages(messages, function() {
                readMessages();
            });
        });
    })();
});
```

See unit tests for more documentation.

Copyright
---------

Copyright (c) 2011 Attachments.me. See LICENSE.txt for
further details.
