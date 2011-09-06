var extend = require('./helpers').extend,
    puts = require('sys').puts,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
var nativeParserError = 'Native bson parser not compiled';
    
exports.Queue = function(params) {
    var defaults = {
        host: 'localhost',
        port: 27017,
        database: 'karait',
        queue: 'messages',
        averageMessageSize: 8192,
        queueSize: 4096,
        errorHandler: function(err) {},
        collectionCreatedHook: function() {}
    };
    extend(this, defaults, params);
    this._initializeQueue(true);
};

exports.Queue.prototype._initializeQueue = function(nativeParser) {
    var _this = this;
    
    try {
        var db = new Db(
            this.database,
            new Server(this.host, this.port, {}),
            {native_parser: nativeParser}
        );
    } catch (e) {
        if (e.indexOf(nativeParserError) > -1) {
           this._initializeQueue(false);
           return;
        } else {
           this.errorHandler(err);
        }
    }
    
    db.open(function(err, db) {
        if (err) {
            _this.errorHandler(err);
        } else {
            _this.db = db;
            _this._createCappedCollection(db);
        }
    });
};

exports.Queue.prototype._createCappedCollection = function(db) {
    var _this = this;
    this.db.createCollection(
        this.queue,
        {
            'capped': true,
            'size': (this.averageMessageSize * this.queueSize),
            'max': this.queueSize,
        }, 
        function(err, collection) {
            if (err) {
                _this.errorHandler(err);
            }
            _this.queueCollection = collection;
            _this._createIndexes();
            _this.collectionCreatedHook();
        }
    );
};

exports.Queue.prototype._createIndexes = function() {
    this.queueCollection.createIndex('_id', function(){});
    this.queueCollection.createIndex('_meta.routing_key', function() {});
    this.queueCollection.createIndex('_meta.expired', function() {});
    this.queueCollection.createIndex('_meta.visible_after', function(){});
}

exports.Queue.prototype.write = function(message, options, callback) {
    if (message.toObject) {
        var messageObject = message.toObject();
    } else {
        var messageObject = message;
    }
    
    messageObject._meta = {
        expire: -1.0,
        timestamp: (new Date()).getTime() / 1000.0,
        expired: false,
        visible_after: -1.0
    }
    this.queueCollection.insert(messageObject, {safe: true}, callback);
};