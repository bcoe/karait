var extend = require('./helpers').extend,
    puts = require('sys').puts;
    
exports.Message = function(params) {
    var defaults = {
    };
    extend(this, defaults, params);
};