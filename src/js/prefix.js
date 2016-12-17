(function() {
    "use strict";
    function buildAlight() {
        var alight = function(element, data) {
            return alight.bootstrap(element, data);
        }
        alight.version = '{{{version}}}';
        alight.filters = {};
        alight.text = {};
        alight.core = {};
        alight.utils = {};
        alight.option = {
            globalController: false,
            removeAttribute: true,
            domOptimization: true,
            fastBinding: true
        };
        alight.debug = {
            scan: 0,
            directive: false,
            watch: false,
            watchText: false,
            parser: false
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
        alight.priority = {
            al: {
                app: 2000,
                checked: 20,
                'class': 30,
                css: 30,
                focused: 20,
                'if': 700,
                'ifnot': 700,
                model: 20,
                radio: 20,
                repeat: 1000,
                select: 20,
                stop: -10,
                value: 20,
                on: 10
            },
            $component: 5,
            $attribute: -5
        };
        var f$ = alight.f$ = {};

        var removeItem = function(list, item) {
            var i = list.indexOf(item);
            if(i >= 0) list.splice(i, 1)
            else console.warn('trying to remove not exist item')
        };
        /* next postfix.js */
