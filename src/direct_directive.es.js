alight.hooks.attribute.unshift({
    code: 'directDirective',
    fn: function() {
        var d = this.attrName.match(/^(.*)\!$/);
        if(!d) return;
        let name = d[1].replace(/(-\w)/g, function(m) {
            return m.substring(1).toUpperCase()
        });
        const fn = this.cd.locals[name] || alight.option.globalController && window[name];
        if(f$.isFunction(fn)) {
            this.directive = function(scope, expression, value, env) {
                fn(scope);
            }
        } else {
            this.result = 'noDirective';
            this.stop = true;
        }
    }
});