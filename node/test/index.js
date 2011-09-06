var queueTests = require('./queue_test'),
    puts = require('sys').puts,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server,
    tests = [];
    
function run(callback, test) {
    var db = new Db('karait_test', new Server('localhost', 27017, {}), {native_parser:false});
    db.open(function(err, db) {
        db.dropCollection('queue_test', function(err, result) {
            callback(
                function() {
                    puts(test + ' [Success]');
                    var nextTest = tests.shift();
                    if (nextTest) {
                        nextTest();
                    }
                },
                test + ': '
            );
        });
    });
}

for (var test in queueTests.tests) {
    (function(func, name) {
        tests.push(function() {
            run(func, name);
        });
    })(queueTests.tests[test], test);
}

tests.shift()();
