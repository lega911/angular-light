(function() {
    function buildAlight(alightConfig) {
        alightConfig = alightConfig || {};
        var enableGlobalControllers = alightConfig.globalControllers;
        var alight = {};
        var f$ = {};
        alight.f$ = f$;


        var removeItem = function(list, item) {
            var i = list.indexOf(item);
            if(i >= 0) list.splice(i, 1)
            else console.warn('trying to remove not exist item')
        };
        /* next postfix.js */