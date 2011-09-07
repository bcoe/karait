var extend = require('./helpers').extend,
    Message = require('./message').Message,
    puts = require('sys').puts,
    mongodb = require('mongodb'),
    Db = mongodb.Db,
    Connection = mongodb.Connection,
    Server = mongodb.Server;
    
var nativeParserError = 'Native bson parser not compiled';
var makeFloat = 0.0000001;
    
exports.Queue = function(params, onQueueReady) {
    
    if (typeof(params) === 'function') {
        onQueueReady = params;
        params = {};
    }
    
    var defaults = {
        host: 'localhost',
        port: 27017,
        database: 'karait',
        queue: 'messages',
        averageMessageSize: 8192,
        queueSize: 4096
    };
    extend(this, defaults, params);
    this.onQueueReady = onQueueReady || function() {};
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
           this.onQueueReady(err, null);
           return;
        }
    }
    
    db.open(function(err, db) {
        if (err) {
            _this.onQueueReady(err, null);
            return;
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
                _this.onQueueReady(err, null);
                return;
            }
            _this.queueCollection = collection;
            _this._createIndexes();
            _this.onQueueReady(null, _this);
        }
    );
};

exports.Queue.prototype._createIndexes = function() {
    this.queueCollection.createIndex('_id', function(){});
    this.queueCollection.createIndex('_meta.routing_key', function() {});
    this.queueCollection.createIndex('_meta.expired', function() {});
    this.queueCollection.createIndex('_meta.visible_after', function(){});
}

exports.Queue.prototype.deleteMessages = function(messages, callback) {
    callback = callback || {};
    
    var deleteIds = [];
    for (var i = 0, message; (message = messages[i]) != null; i++) {
        deleteIds.push(message._source._id);
    }
        
    this.queueCollection.update(
        {
            _id: {
                $in: deleteIds
            }
        },
        {
            $set: {
                '_meta.expired': true
            }
        },
        {
            safe: true,
            multi: true
        },
        callback
    );
};

exports.Queue.prototype.write = function(message, params, callback) {
    
    if (typeof(params) === 'function') {
        callback = params;
        params = {};
    }
    
    callback = callback || function() {};
    
    if (message.toObject) {
        var messageObject = message.toObject();
    } else {
        var messageObject = message;
    }
    
    messageObject._meta = {
        expire: (params.expire || -1) - makeFloat,
        timestamp: (new Date()).getTime() / 1000.0,
        expired: false,
        visible_after: -1 - makeFloat
    }
    
    if (params.routingKey) {
        messageObject._meta.routing_key = params.routingKey;
    }
    
    this.queueCollection.insert(messageObject, {safe: true}, callback);
};

exports.Queue.prototype.read = function(params, callback) {
    var _this = this,
        params = params || {};
    
    if (typeof(params) === 'function') {
        callback = params;
        params = {};
    }
    
    callback = callback || function() {};
    
    extend(
        params,
        {
            messagesRead: 10,
            visibilityTimeout: -1.0 - makeFloat,
            routingKey: null
        },
        params
    );
    
    var currentTime = (new Date()).getTime() / 1000.0,
        query = {
            '_meta.expired': false,
            '_meta.visible_after': {
                '$lt': currentTime
            }
        },
        update = false;
    
    if (params.routingKey) {
        query['_meta.routing_key'] = params.routingKey
    } else {
        query['_meta.routing_key'] = {
            '$exists': false
        }
    }
    
    if (params.visibilityTimeout > -1.0) {
        update = {
            '$set': {
              '_meta.visible_after': currentTime + params.visibilityTimeout
            }
        }
    }
    
    if (!update) {
        this._normalFind(query, params.messagesRead, callback);
    } else {
        this._atomicFind(query, update, params.messagesRead, callback);
    }
};

exports.Queue.prototype._normalFind = function(query, limit, callback) {
    
    var messages = [],
        _this = this;
        
    this.queueCollection.find(query, {limit: limit}, function(err, cursor) {
        if (err) {
            callback(err, null);
            return;
        } else {
           cursor.toArray(function(err, items) {
               if (err) {
                   callback(err, null);
                   return;
               } else {
                   for (var i = 0, item; (item = items[i]) != null; i++) {
                       var message = new Message(item, _this.queueCollection);
                       if (!message.isExpired()) {
                           messages.push(message);
                       }
                   }
                   callback(null, messages);
               }
           });
        }
    });
};

exports.Queue.prototype._atomicFind = function(query, update, limit, callback) {
    var messages = [],
        count = 0,
        _this = this;
        
   (function fetchDocument() {
        _this.queueCollection.findAndModify(query, [], update, {}, function(err, item) {
            if (item) {
                var message = new Message(item, _this.queueCollection);
                
                if (!message.isExpired()) {
                    messages.push(message);
                }
            }
            
            if ( (count++) < (limit - 1) ) {
                fetchDocument();
            } else {
                callback(null, messages);
            }
        })
    })();
};