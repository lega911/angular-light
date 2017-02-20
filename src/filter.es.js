
alight.core.getFilter = function(name, cd) {
    var filter = cd.locals[name];
    if(filter && (f$.isFunction(filter) || filter.init || filter.fn)) return filter;
    filter = alight.filters[name];
    if(filter) return filter;
    throw 'Filter not found: ' + name;
}


function makeSimpleFilter(filter, option) {
    var onStop;
    var values = [];
    var active = false;
    var cd = option.cd;
    var callback = option.callback;

    if(option.filterConf.args.length) {
        var watchers = [];

        option.filterConf.args.forEach((exp, i) => {
            const w = cd.watch(exp, function(value) {
                values[i+1] = value;
                handler();
            });
            if(!w.$.isStatic) watchers.push(w);
        });

        var planned = false;
        var handler = function() {
            if(!planned) {
                planned = true;
                cd.watch('$onScanOnce', () => {
                    planned = false;
                    if(active) {
                        var result = filter.apply(null, values);
                        if(f$.isPromise(result)) {
                            result.then(function(value) {
                                callback(value);
                                cd.scan();
                            });
                        } else callback(result);
                    }
                })
            }
        }
        if(watchers.length) {
            onStop = function() {
                watchers.forEach(w => w.stop())
            }
        }
    } else {
        var handler = function() {
            var result = filter(values[0]);
            if(f$.isPromise(result)) {
                result.then(function(value) {
                    callback(value);
                    cd.scan();
                });
            } else callback(result);
        }
    }

    var node = {
        onChange: function(value) {
            active = true;
            values[0] = value;
            handler();
        },
        onStop: onStop,
        watchMode: option.watchMode
    };
    return node;
}

alight.core.buildFilterNode = function(cd, filterConf, filter, callback) {
    if(f$.isFunction(filter)) {
        return makeSimpleFilter(filter, {cd, filterConf, callback});
    } else if(filter.init) {
        return filter.init.call(cd, cd.scope, filterConf.raw, {
            setValue: callback,
            conf: filterConf,
            changeDetector: cd
        });
    } else if(f$.isFunction(filter.fn)) {
        return makeSimpleFilter(filter.fn, {cd, filterConf, callback, watchMode: filter.watchMode});
    }

    throw 'Wrong filter: ' + filterConf.name;
}


function makeFilterChain(cd, ce, prevCallback, option) {
    var watchMode = null;

    const oneTime = option.oneTime;
    if(option.isArray) watchMode = 'array'
    else if(option.deep) watchMode = 'deep';

    if(!prevCallback) {
        let watchObject = {
            el: option.element,
            ea: option.elementAttr
        };
        prevCallback = function(value) {
            execWatchObject(cd.scope, watchObject, value);
        }
    }

    var chain = alight.utils.parsFilter(ce.filter);
    var onStop = [];

    for(var i=chain.result.length-1;i>=0;i--) {
        var filter = alight.core.getFilter(chain.result[i].name, cd);
        var node = alight.core.buildFilterNode(cd, chain.result[i], filter, prevCallback);
        if(node.watchMode) watchMode = node.watchMode;
        if(node.onStop) onStop.push(node.onStop);
        prevCallback = node.onChange;
    };

    option = {
        oneTime: oneTime
    };
    if(watchMode === 'array') option.isArray = true;
    else if(watchMode === 'deep') option.deep = true;

    if(onStop.length) {
        option.onStop = function() {
            onStop.forEach(fn => fn())
            onStop.length = 0;
        }
    }

    return cd.watch(ce.expression, prevCallback, option);
};