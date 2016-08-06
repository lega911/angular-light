alight.hooks.attribute.unshift({
    code: 'directDirective',
    fn: function() {
        var d = this.attrName.match(/^([^()]*)\(\)$/);
        if(!d) d = this.attrName.match(/^\*(.*)$/);
        if(!d) return;
        let name = d[1].replace(/(-\w)/g, function(m) {
            return m.substring(1).toUpperCase()
        });
        this.directive = this.cd.locals[name] || window[name];
        if(!this.directive) {
            this.result = 'noDirective';
            this.stop = true;
        }
    }
});