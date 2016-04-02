f$.ready = (function() {
    var callbacks = [];
    var ready = false;
    function onReady() {
        ready = true;
        f$.off(document, 'DOMContentLoaded', onReady);
        for(var i=0;i<callbacks.length;i++)
            callbacks[i]();
        callbacks.length = 0;
    };
    f$.on(document, 'DOMContentLoaded', onReady);
    return function(callback) {
        if(ready) callback();
        else callbacks.push(callback)
    }
})();
