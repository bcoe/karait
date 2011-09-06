exports.extend = function(o1, o2, o3) {
    var punch = function(o1, o2) {
        for (var key in o2) {
            if (o2.hasOwnProperty(key)) {
                o1[key] = o2[key];
            }
        }
    };
    punch(o1, o2);
    punch(o1, o3);
}