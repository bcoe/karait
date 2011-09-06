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