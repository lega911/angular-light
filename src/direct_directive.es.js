alight.hooks.attribute.unshift({
    code: 'directDirective',
    fn: function() {
        var d = this.attrName.match(/^(.*)\!$/);
        if(!d) return;
        let name = d[1].replace(/(-\w)/g, function(m) {
            return m.substring(1).toUpperCase()
        });
        const fn = this.cd.locals[name] || alight.ctrl[name] || alight.option.globalController && window[name];
        if(f$.isFunction(fn)) {
            this.directive = function(scope, element, value, env) {
                const cd = env.changeDetector;
                if(value) {
                    var args = alight.utils.parsArguments(value);
                    var values = Array(args.result.length);
                    for(var i=0; i<args.result.length;i++) {
                        values[i] = alight.utils.compile.expression(args.result[i], {
                            input: ['$element', '$env']
                        }).fn(cd.locals, element, env);
                    }
                    fn.apply(cd, values);
                } else {
                    fn.call(cd, scope, element, value, env);
                }
            }
        } else {
            this.result = 'noDirective';
            this.stop = true;
        }
    }
});