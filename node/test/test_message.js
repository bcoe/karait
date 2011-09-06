var equal = require('assert').equal,
    puts = require('sys').puts,
    Message = require('../lib').Message,
    Queue = require('../lib').Queue,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
exports.tests = {
    'should punch variables onto message when initialized with a dictionary': function(finished, prefix) {
        var message = new Message({
            'foo': 99,
            'inner_dictionary': {
               'bar': 10
            }
        });
        equal(99, message.foo, prefix + 'foo not equal to 99');
        equal(10, message.inner_dictionary.bar, prefix + 'bar not equal to 10');
        finished();
    },
    
    'should serialize appropriate variables when toObject is called': function(finished, prefix) {
        var object = {
            'apple': 7,
            'banana': 5,
            'inner_dictionary': {
                'foo': 2,
                'bar': 4
            }
        };
        var message = new Message(object);
        var rawMessage = message.toObject();

        var count = 0;
        for (var key in rawMessage) {
            if (rawMessage.hasOwnProperty(key)) {
                count += 1;
            }
        }
        
        equal(2, rawMessage.inner_dictionary.foo, prefix + 'foo had wrong value');
        equal(3, count, prefix + 'wrong number of keys serialized.');
        finished();
    },
    
    'should not serialize black listed keys when toObject is called': function(finished, prefix) {
        var object = {
            '_id': 'foobar',
            '_meta': {
                'foo': 2
            },
            'foo': 5
        };
        var message = new Message(object);
        var rawMessage = message.toObject();
        equal(null, rawMessage._id, prefix + '_id was serialized');
        equal(null, rawMessage._meta, prefix + '_meta was serialized');
        equal(5, rawMessage.foo, prefix + 'foo was not serialized');
        finished();
    },

    'should remove a message from mongodb when delete is called on it': function(finished, prefix) {
        var queue = new Queue({
            database: 'karait_test',
            queue: 'queue_test',
            averageMessageSize: 8192,
            queueSize: 4096,
            onQueueReady: function() {
                queue.write({'foo': 'bar'}, {}, function() {
                    queue.read(function(err, messages) {
                        equal(1, messages.length, prefix + 'queue does not have one message');
                        messages[0].delete(function() {
                            queue.read(function(err, messages) {
                                equal(0, messages.length, prefix + 'queue is not empty');
                                finished();
                            });
                        });
                    });
                });
            }
        });
    }/*,
    
    'should set a message to expired if current time > than expires time': function(finished, prefix) {
        var queue = new Queue({
            database: 'karait_test',
            queue: 'queue_test',
            averageMessageSize: 8192,
            queueSize: 4096,
            onQueueReady: function() {
                queue.write({'foo': 'bar'}, {expires: 0.01}, function() {
                    queue.read(function(err, messages) {
                        equal(1, messages.length, prefix + 'queue does not have one message');
                        messages[0].delete(function() {
                            queue.read(function(err, messages) {
                                equal(0, messages.length, prefix + 'queue is not empty');
                                finished();
                            });
                        });
                    });
                });
            }
        });
    }*/
};