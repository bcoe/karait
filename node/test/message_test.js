var a = require('assert'),
    puts = require('sys').puts,
    Message = require('../lib').Queue,
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
        a.equal(99, message.foo, prefix + 'foo not equal to 99');
        a.equal(10, message.inner_dictionary.bar, prefix + 'bar not equal to 10');
        finished();
    }
};