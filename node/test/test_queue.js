var equal = require('assert').equal,
    puts = require('sys').puts,
    Queue = require('../lib').Queue,
    Message = require('../lib').Message,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
exports.tests = {
    'should initialize a capped collection when a queue is created': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.queueCollection.options(function(err, options) {
                    equal(true, options.capped, prefix + 'collection not capped');
                    equal(4096, options.max, prefix + 'invalid max queue size');
                    equal( (4096 * 8192) , options.size, prefix + 'invalid queue size');
                    
                    finished();
                });
            }
        );
    },
    
    'should attach to a collection that already exists': function(finished, prefix) {
        var db = new Db('karait_test', new Server('localhost', 27017, {}), {native_parser:false});
        db.open(function(err, db) {
            db.createCollection('queue_test', {}, function(err, collection) {
                collection.insert(
                    {
                        message: {
                          apple: 3,
                          banana: 5
                        },
                        _meta: {
                          timestamp: 2523939,
                          expire: 20393,
                          routing_key: 'foo_key'
                        }
                    },
                    {
                        safe: true
                    }
                );
                
                new Queue(
                    {
                        database: 'karait_test',
                        queue: 'queue_test',
                        averageMessageSize: 8192,
                        queueSize: 4096
                    },
                    function(err, queue) {
                        queue.queueCollection.options(function(err, options) {
                            collection.count({}, function(err, count) {
                                equal(1, count, prefix + 'count should be 1.');
                                finished();
                            });
                        });
                    }
                );
                
            });
        });
    },

    'should write a dictionary into the mongodb queue collection': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write(
                    {
                        foo: 'bar'
                    }, 
                    function() {
                        var db = new Db('karait_test', new Server('localhost', 27017, {}), {native_parser:false});
                        db.open(function(err, db) {
                            db.createCollection('queue_test', {}, function(err, collection) {
                                collection.findOne({}, function(err, rawMessage) {
                                    equal('bar', rawMessage.foo, prefix + 'foo key not set');
                                    equal(true, rawMessage._meta.timestamp > 0, prefix + 'timestamp was not set');
                                    finished();
                                });
                            });
                        });
                    }
                );
            }
        );
    },
    
    'should write a message object into the mongodb queue collection': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                var message = new Message(
                    {
                        'bar': 'foo'
                    }
                );
                
                queue.write(
                    message,
                    function() {
                        var db = new Db('karait_test', new Server('localhost', 27017, {}), {native_parser:false});
                        db.open(function(err, db) {
                            db.createCollection('queue_test', {}, function(err, collection) {
                                collection.findOne({}, function(err, rawMessage) {
                                    var count = 0;
                                    for (var key in rawMessage) {
                                        count += 1;
                                    }
                                    equal('foo', rawMessage.bar, prefix + 'foo key not set');
                                    equal(3, count, prefix + 'rawMessage had wrong number of keys');
                                    equal(true, rawMessage._meta.timestamp > 0, prefix + 'timestamp was not set');
                                    finished();
                                });
                            });
                        });
                    }
                );
            }
        );
    },
    
    'should read a messge object from the mongo queue collection': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                writeMessage = new Message({
                   foo: 1,
                   bar: 2,
                   innerObject: {
                       apple: 3
                   }
                });
                queue.write(writeMessage, {}, function() {
                    queue.read(function(err, messages) {
                        var readMessage = messages[0];
                        equal(1, readMessage.foo, prefix + 'foo not set');
                        equal(3, readMessage.innerObject.apple, prefix + 'inner object not found');
                        finished();
                    });
                });
            }
        );
    },
    
    'should only return messages that match routing key': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, {routingKey: 'foobar'}, function() {
                    queue.write({bar: 'foo'}, function() {
                        queue.read({routingKey: 'foobar'}, function(err, messages) {
                            equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                            equal('bar', messages[0].foo, prefix + messages[0].foo + ' not equal to bar');
                            queue.read(function(err, messages) {
                                equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                                equal('foo', messages[0].bar, prefix + messages[0].bar + ' not equal to foo');
                                finished();
                            });
                        });
                    });
                });
            }
        );
    },
    
    'should no longer return a message when delete is called on it': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, function() {
                    queue.read(function(err, messages) {
                        equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                        messages[0].delete(function() {
                            queue.read(function(err, messages) {
                                equal(0, messages.length, prefix + messages.length + ' not equal to 0');
                                finished();
                            });
                        });
                    });
                });
            }
        );
    },
    
    'should not return expired messages when read is called': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, {expire: 0.1}, function() {
                    setTimeout(function() {
                        queue.read(function(err, messages) {
                            equal(0, messages.length, prefix + messages.length + ' not equal to 0');
                            finished();
                        });
                    }, 200);
                });
            }
        );
    },
    
    'should not immediately expire a message when written if expire set': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, {expire: 0.1}, function() {
                    setTimeout(function() {
                        queue.read(function(err, messages) {
                            equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                            finished();
                        });
                    }, 1);
                });
            }
        );
    },
    
    'should remove all messages when deleteMessages() is called with an array of messages': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, function() {
                    queue.write({foo: 'bar'}, function() {
                        queue.read(function(err, messages) {
                            equal(2, messages.length, prefix + messages.length + ' not equal to 2');
                            queue.deleteMessages(messages, function() {
                                queue.read(function(err, messages) {
                                    equal(0, messages.length, prefix + messages.length + ' not equal to 0');
                                    finished();
                                });
                            });
                        });
                    });
                });
            }
        );
    },
    
    'should not see a message until the visibility timeout has passed': function(finished, prefix) {
        new Queue(
            {
                database: 'karait_test',
                queue: 'queue_test',
                averageMessageSize: 8192,
                queueSize: 4096
            },
            function(err, queue) {
                queue.write({foo: 'bar'}, function() {
                    queue.read({visibilityTimeout: 0.1}, function(err, messages) {
                        equal('bar', messages[0].foo, prefix + messages[0].foo + ' not equal to bar');
                        equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                        queue.read(function(err, messages) {
                            equal(0, messages.length, prefix + messages.length + ' not equal to 0');
                            setTimeout(function() {
                                queue.read(function(err, messages) {
                                    equal(1, messages.length, prefix + messages.length + ' not equal to 1');
                                    finished();
                                });
                            }, 200);
                        });
                    });
                });
            }
        );
    }
};