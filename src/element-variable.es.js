function setElementToName(scope, element, value, env) {
    env.setValue(env.attrArgument, element);
};

alight.hooks.attribute.unshift({
    code: 'elementVariable',
    fn: function() {
        var d = this.attrName.match(/^#([\w\.]*)$/);
        if(!d) return;
        this.directive = setElementToName;
        this.attrArgument = d[1];
    }
});