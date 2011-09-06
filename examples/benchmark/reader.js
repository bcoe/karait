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
