var queueTests = require('./test_queue'),
    messageTests = require('./test_message'),
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
                    puts(test + ' \033[32m[Success]\033[m');
                    if (tests.length == 0) {
                        puts(' \033[32mAll tests finished.\033[m');
                        process.exit();
                    }
                    
                    var nextTest = tests.shift();
                    nextTest();
                },
                test + ': '
            );
        });
    });
}

function addTests(testsObject) {
    for (var test in testsObject) {
        (function(func, name) {
            tests.push(function() {
                run(func, name);
            });
        })(testsObject[test], test);
    }
}

addTests(queueTests.tests);
addTests(messageTests.tests);
tests.shift()();