var a = require('assert'),
    puts = require('sys').puts,
    Queue = require('../lib').Queue,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
exports.tests = {
    'should initialize a capped collection when a queue is created': function(finished, prefix) {
        var queue = new Queue({
            database: 'karait_test',
            queue: 'queue_test',
            averageMessageSize: 8192,
            queueSize: 4096,
            collectionCreatedHook: function() {
                queue.queueCollection.options(function(err, options) {
                    a.equal(true, options.capped, prefix + 'collection not capped');
                    a.equal(4096, options.max, prefix + 'invalid max queue size');
                    a.equal( (4096 * 8192) , options.size, prefix + 'invalid queue size');
                    
                    finished();
                });
            }
        });
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
                
                var queue = new Queue({
                    database: 'karait_test',
                    queue: 'queue_test',
                    averageMessageSize: 8192,
                    queueSize: 4096,
                    collectionCreatedHook: function() {
                        queue.queueCollection.options(function(err, options) {
                            collection.count({}, function(err, count) {
                                a.equal(1, count, prefix + 'count should be 1.');
                                finished();
                            });
                        });
                    }
                });
                
            });
        });
    },
    
    'write a dictionary into the mongodb queue collection': function(finished, prefix) {
        var queue = new Queue({
            database: 'karait_test',
            queue: 'queue_test',
            averageMessageSize: 8192,
            queueSize: 4096,
            collectionCreatedHook: function() {
                queue.write({
                   foo: 'bar'
                });
                
                var db = new Db('karait_test', new Server('localhost', 27017, {}), {native_parser:false});
                db.open(function(err, db) {
                    db.createCollection('queue_test', {}, function(err, collection) {
                        collection.findOne({}, function(err, rawMessage) {
                            a.equal('bar', rawMessage.foo, prefix + 'foo key not set');
                            a.equal(true, rawMessage._meta.timestamp > 0, prefix + 'timestamp was not set');
                            finished();
                        });
                    });
                });
            }
        });
    }
}