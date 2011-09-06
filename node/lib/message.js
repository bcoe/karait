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
}