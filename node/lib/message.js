var extend = require('./helpers').extend,
    puts = require('sys').puts;
    
exports.Message = function(params) {
    var defaults = {
    };
    extend(this, defaults, params);
};

exports.Message.prototype.BLACKLIST = {
    '_meta': true,
    '_id': true,
    '_source': true,
    '_expired': true,
    '_queue_collection': true
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