var extend = require('./helpers').extend,
    puts = require('sys').puts;
    
exports.Message = function(source, queueCollection) {
    this._source = source || {};
    this._queueCollection = queueCollection;
    for (var key in this._source) {
        if (this._source.hasOwnProperty(key) && !this.BLACKLIST[key]) {
            this[key] = this._source[key];
        }
    }
    this._checkIfExpired();
};

exports.Message.prototype._checkIfExpired = function() {
    var meta = this._source._meta || {},
        expire = meta.expire || -1.0,
        currentTime = (new Date()).getTime() / 1000.0,
        timestamp = meta.timestamp || 0.0;
        
    if (expire <= -1.0) {
        return;
    }
    
    if ( (currentTime - timestamp) > expire ) {
       this._expired = true;
       this.delete();
    }
};

exports.Message.prototype.BLACKLIST = {
    '_meta': true,
    '_id': true,
    '_source': true,
    '_expired': true,
    '_queueCollection': true
};

exports.Message.prototype.toObject = function() {
    var object = {};
    for (var key in this) {
        if (this.hasOwnProperty(key) && !this.BLACKLIST[key]) {
            object[key] = this[key];
        }
    }
    return object;
};

exports.Message.prototype.delete = function(callback) {
    callback = callback || function() {};
    this._queueCollection.update(
        {
            '_id': this._source._id
        },
        {
            '$set': {
                '_meta.expired': true
            }
        },
        callback
    );
};

exports.Message.prototype.isExpired = function() {
    return this._expired;
};