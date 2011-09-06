exports.extend = function() {
    var punch = function(o1, o2) {
        for (var key in o2) {
            if (o2.hasOwnProperty(key)) {
                o1[key] = o2[key];
            }
        }
    };
    
    if (arguments.length == 3) {
        punch(arguments[1], arguments[2]);
        punch(arguments[0], arguments[1]);
        return;
    }
    
    if (arguments.length == 2) {
        punch(arguments[0], arguments[1]);
        return;
    }
}