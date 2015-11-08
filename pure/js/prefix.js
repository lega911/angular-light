(function() {
    function buildAlight() {
        var alight = {
            filters: {},
            text: {},
            core: {},
            utils: {},
            directives: {
                al: {},
                bo: {},
                ctrl: {}
            },
            hooks: {
                directive: [],
                binding: []
            }
        };
        var f$ = {};
        alight.f$ = f$;
        alight.d = alight.directives;

        var removeItem = function(list, item) {
            var i = list.indexOf(item);
            if(i >= 0) list.splice(i, 1)
            else console.warn('trying to remove not exist item')
        };
        /* next postfix.js */