(function() {
    const baseFilterNode = alight.core.buildFilterNode;
    alight.core.buildFilterNode = function(cd, filterConf, filterObject, callback) {
        if(f$.isFunction(filterObject) && Object.keys(filterObject.prototype).length) {
            var filter = new filterObject(filterConf.raw, cd.scope, {
                setValue: callback,
                changeDetector: cd
            });
            filter.setValue = callback;

            var result = {};
            if(filter.watchMode) result.watchMode = filter.watchMode;
            if(filter.onStop) result.onStop = filter.onStop.bind(filter);
            if(filter.onChange) result.onChange = filter.onChange.bind(filter);
            return result;
        }
        return baseFilterNode(cd, filterConf, filterObject, callback);
    }
})();