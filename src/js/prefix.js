(function() {
    "use strict";
    function buildAlight() {
        var alight = {
            filters: {},
            text: {},
            ctrl: {},
            core: {},
            utils: {},
            d: {
                al: {},
                bo: {}
            },
            hooks: {
                directive: [],
                binding: []
            }
        };
        var f$ = {};
        alight.f$ = f$;
        alight.directives = alight.d;
        alight.controllers = alight.ctrl;

        var removeItem = function(list, item) {
            var i = list.indexOf(item);
            if(i >= 0) list.splice(i, 1)
            else console.warn('trying to remove not exist item')
        };
        /* next postfix.js */
