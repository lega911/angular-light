
alight.d.al.if = function(scope, element, name, env) {
    if(env.elementCanBeRemoved) {
        alight.exceptionHandler(null, `${env.attrName} cant control element because of ${env.elementCanBeRemoved}`, {
            scope: scope,
            element: element,
            value: name,
            env: env
        });
        return {};
    }
    env.stopBinding = true
    let self = {
        item: null,
        childCD: null,
        base_element: null,
        top_element: null,
        start: () => {
            self._name = name;
            self.controller = env.changeDetector.ifController;
            self.initControl();
            self.prepare();
            self.watchModel();
        },
        initControl: () => {
            self.index = 0;
            self.controller = env.changeDetector.ifController = {
                index: 1,
                active: null,
                whoActive: [],
                last: null,
                update: () => {
                    let active;
                    for(let i of self.controller.whoActive) {
                        if(!i) continue;
                        active = i;
                        break;
                    }
                    if(!active) active = self.controller.last;
                    if(self.controller.active !== active) {
                        if(self.controller.active) self.controller.active.removeBlock();
                        self.controller.active = active;
                        if(active) active.insertBlock();
                    }
                }
            };
        },
        prepare: () => {
            self.base_element = element;
            self.top_element = document.createComment(` ${env.attrName}: ${name} `);
            f$.before(element, self.top_element);
            f$.remove(element);
        },
        updateDom: (value) => {
            if(value) self.controller.whoActive[self.index] = self;
            else self.controller.whoActive[self.index] = null;
            self.controller.update();
        },
        removeBlock: () => {
            if(!self.childCD) return;
            self.childCD.destroy();
            self.childCD = null;
            self.removeDom(self.item);
            self.item = null;
        },
        insertBlock: () => {
            if(self.childCD) return;
            self.item = self.base_element.cloneNode(true);
            self.insertDom(self.top_element, self.item);
            self.childCD = env.new();

            alight.bind(self.childCD, self.item, {
                skip_attr: env.skippedAttr(),
                elementCanBeRemoved: env.attrName
            });
        },
        watchModel: () => env.watch(name, self.updateDom, {readOnly: true}),
        removeDom: (element) => f$.remove(element),
        insertDom: (base, element) => f$.after(base, element)
    }
    return self;
}

alight.d.al.elseIf = function(scope, element, name, env) {
    let self = alight.d.al.if(scope, element, name, env);
    self.initControl = () => {
        self.index = self.controller.index++;
    }
    return self;
}

alight.d.al.else = function(scope, element, name, env) {
    let self = alight.d.al.if(scope, element, name, env);
    self.initControl = () => {
        self.controller.last = self;
    }
    self.watchModel = () => {}
    return self;
}
