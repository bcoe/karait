var extend = require('./helpers').extend,
    puts = require('sys').puts;
    
exports.Message = function(params) {
    var defaults = {
    };
    extend(this, defaults, params);
};

exports.Message.prototype.toObject = function() {
    var object = {};
    for (var key in this) {
        if (this.hasOwnProperty(key)) {
            object[key] = this[key];
        }
    }
    return object;
};