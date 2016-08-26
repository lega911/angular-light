
function getFilter(name, cd) {
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


function makeFilterChain(cd, ce, baseCallback, option) {
    var watchMode = null;

    if(option.isArray) watchMode = 'array'
    else if(option.deep) watchMode = 'deep';
    
    var prevCallback = baseCallback;
    var conf = alight.utils.parsFilter(ce.filter);
    var filter;

    for(var i=conf.result.length-1;i>=0;i--) {
        var f = conf.result[i];
        filter = getFilter(f.name, cd);

        if(f$.isFunction(filter)) {
            prevCallback = (function(filter, prevCallback) {
                var values = [];

                if(f.args.length) {
                    f.args.forEach((exp, i) => {
                        cd.watch(exp, function(value) {
                            values[i+1] = value;
                            handler();
                        });
                    });

                    var planned = false;
                    var handler = function() {
                        if(!planned) {
                            planned = true;
                            cd.watch('$onScanOnce', () => {
                                planned = false;
                                prevCallback(filter.apply(null, values));
                            })
                        }
                    }
                } else {
                    var handler = function() {
                        prevCallback(filter.apply(null, values));
                    }
                }

                return function(value) {
                    values[0] = value;
                    handler();
                };
            })(filter, prevCallback);

        } else {

        }

    };

    option = {};
    if(watchMode === 'array') option.isArray = true;
    else if(watchMode === 'deep') option.deep = true;

    return cd.watch(ce.expression, prevCallback, option);
};