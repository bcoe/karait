var a = require('assert'),
    puts = require('sys').puts,
    Message = require('../lib').Queue,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
exports.tests = {
    'should punch variables onto message when initialized with a dictionary': function(finished, prefix) {
        finished();
    }
};