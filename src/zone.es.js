!function(){
    function zoneJSInvoker(_0, zone, _2, task, _4, args) {
        task.callback.apply(null, args);
        var root = zone._properties.root;
        if(root && root.topCD) root.topCD.scan({zone: true});
    }

    var bind = alight.bind;
    alight.bind = function(cd, el, option) {
        var root = cd.root;
        var oz = alight.option.zone;
        if(oz) {
            var Z = oz===true?Zone:oz;
            var zone = root.zone;
            if(!zone) {
                root.zone = zone = Z.current.fork({
                    name: Z.current.name + '.x',
                    properties: {root: root},
                    onInvokeTask: zoneJSInvoker
                })
            }
            if(Z.current !== zone) return root.zone.run(bind, null, [cd, el, option]);
        }
        return bind(cd, el, option);
    }
}();