var equal = require('assert').equal,
    puts = require('sys').puts,
    Message = require('../lib').Message,
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
        equal(null, rawMessage._id, '_id was serialized');
        equal(null, rawMessage._meta, '_meta was serialized');
        equal(5, rawMessage.foo, 'foo was not serialized');
    }
};