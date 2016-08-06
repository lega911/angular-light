(function() {
    "use strict";
    function buildAlight() {
        var alight = function(element, data) {
            return alight.bootstrap(element, data);
        }
        alight.filters = {};
        alight.text = {};
        alight.core = {};
        alight.utils = {};
        alight.option = {
            injectScope: false
        };
        alight.ctrl = alight.controllers = {};
        alight.d = alight.directives = {
            al: {},
            bo: {},
            $global: {}
        };
        alight.hooks = {
            directive: [],
            binding: []
        };
        var f$ = alight.f$ = {};

        var removeItem = function(list, item) {
            var i = list.indexOf(item);
            if(i >= 0) list.splice(i, 1)
            else console.warn('trying to remove not exist item')
        };
        /* next postfix.js */
