
alight.core.getFilter = function(name, cd) {
    var error = false;
    var scope = cd.scope;
    var filter = null;
    if(scope.$ns && scope.$ns.filters) {
        filter = scope.$ns.filters[name];
        if(!filter && !scope.$ns.inheritGlobal) error = true
    }
    if(!filter && !error) filter = alight.filters[name];
    if(!filter) throw 'Filter not found: ' + name;
    return filter;
}


alight.core.buildFilterNode = function(cd, filterConf, filter, callback) {
    if(f$.isFunction(filter)) {
        var onStop;
        var values = [];
        var active = false;

        if(filterConf.args.length) {
            var watchers = [];

            filterConf.args.forEach((exp, i) => {
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
                        if(active) callback(filter.apply(null, values));
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
                callback(filter(values[0]));
            }
        }

        var node = {
            onChange: function(value) {
                active = true;
                values[0] = value;
                handler();
            },
            onStop: onStop
        };
        return node;
    } else if(filter.init) {
        return filter.init.call(cd, cd.scope, filterConf.raw, {
            setValue: callback,
            conf: filterConf,
            changeDetector: cd
        });
    }
    throw 'Wrong filter: ' + filterConf.name;
}


function makeFilterChain(cd, ce, prevCallback, option) {
    var watchMode = null;

    const oneTime = option.oneTime;
    if(option.isArray) watchMode = 'array'
    else if(option.deep) watchMode = 'deep';

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