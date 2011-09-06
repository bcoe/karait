var a = require('assert'),
    puts = require('sys').puts,
    Queue = require('../lib').Queue;
    
exports.tests = {
    'should initialize a capped collection when a queue is created': function(finished) {
        var queue = new Queue({
            database: 'karait_test',
            queue: 'queue_test',
            averageMessageSize: 8192,
            queueSize: 4096,
            collectionCreatedHook: function() {
                queue.queueCollection.options(function(err, options) {
                    a.equal(true, options.capped, 'collection not capped');
                    a.equal(4096, options.max, 'invalid max queue size');
                    a.equal( (4096 * 8192) , options.size, 'invalid queue size');

                    finished();
                });
            }
        });
    }
}