
alight.d.al.checked = function(scope, element, name, env) {
    let fbData = env.fbData = {
        opt: {},
        watch: []
    };

    function eattr(attrName) {
        let result = env.takeAttr(attrName);
        if(alight.option.removeAttribute) {
            element.removeAttribute(attrName);
            if(env.fbElement) env.fbElement.removeAttribute(attrName);
        }
        return result;
    }

    function takeAttr(name, attrName) {
        let text = eattr(attrName);
        if(text) {
            fbData.opt[name] = text;
            return true;
        } else {
            let exp = eattr(':' + attrName) || eattr('al-attr.' + attrName);
            if(exp) {
                fbData.watch.push([exp, name]);
                return true;
            }
        }
    }

    function applyOpt(opt, env, updateDOM) {
        for(let k in env.fbData.opt) {
            opt[k] = env.fbData.opt[k];
        }

        for(let w of env.fbData.watch) {
            let name = w[1];
            env.watch(w[0], (value) => {
                opt[name] = value;
                updateDOM();
            });
        }
    }

    if(takeAttr('value', 'value')) {
        env.fastBinding = function(scope, element, name, env) {
            let watch, array = null;

            function updateDOM() {
                element.checked = array && array.indexOf(opt.value) >= 0;
                return '$scanNoChanges';
            };

            let opt = {};
            applyOpt(opt, env, updateDOM);

            watch = env.watch(name, (input) => {
                array = input;
                if(!Array.isArray(array)) array = null;
                updateDOM();
            }, {isArray: true});

            env.on(element, 'change', () => {
                if(!array) {
                    array = [];
                    env.setValue(name, array);
                }

                if(element.checked) {
                    if(array.indexOf(opt.value) < 0) array.push(opt.value);
                } else {
                    let i = array.indexOf(opt.value);
                    if(i >= 0) array.splice(i, 1);
                }
                watch.refresh();
                env.scan();
                return
            });
        }
    } else {
        takeAttr('true', 'true-value');
        takeAttr('false', 'false-value');

        env.fastBinding = function(scope, element, name, env) {
            let value, watch;
            let opt = {
                true: true,
                false: false
            };

            function updateDOM() {
                element.checked = value === opt.true;
                return '$scanNoChanges';
            };

            applyOpt(opt, env, updateDOM);

            watch = env.watch(name, (input) => {
                value = input;
                updateDOM();
            });

            env.on(element, 'change', () => {
                value = element.checked?opt.true:opt.false;
                env.setValue(name, value);
                watch.refresh();
                env.scan();
                return
            });
        }
    }

    env.fastBinding(scope, element, name, env);
}