{

    let textHandler = makeHandler(
        (element) => element.value,
        (element, value) => {
            if(value == null) value = '';
            element.value = value;
        }
    );

    let numberHandler = makeHandler(
        (element) => element.valueAsNumber,
        (element, value) => {
            element.valueAsNumber = value;
        }
    );

    let dateHandler = makeHandler(
        (element) => element.valueAsDate,
        (element, value) => {
            element.valueAsDate = value;
        }
    );

    let types = {
        'text': textHandler,
        'range': numberHandler,
        'number': numberHandler,
        'checkbox': checkboxHandler,
        'radio': radioHandler,
        'date': dateHandler,
        'time': numberHandler,
        //'datetime': dateHandler,
        'datetime-local': numberHandler
    };

    alight.d.al.model = function(scope, element, value, env) {
        let elName = element.nodeName.toLowerCase();
        if(elName === 'input') {
            let handler = types[element.type] || types.text;

            handler(scope, element, value, env);
        } else if(elName === 'select') {

        } else { // component?

        }

    }


    function makeHandler(getter, watchFn) {
        return function(scope, element, variable, env) {
            env.fastBinding = true;
            let watch;

            let updateModel = function() {
                env.setValue(variable, getter(element));
                watch.refresh();
                env.scan();
            }

            env.on(element, 'input', updateModel);
            env.on(element, 'change', updateModel);

            watch = env.watch(variable, (value) => watchFn(element, value), {readOnly: true});
        };
    };

    function radioHandler(scope, element, name, env) {
        let value, watch;

        let key = env.takeAttr('al-value')
        if(key) value = env.eval(key)
        else value = env.takeAttr('value');

        env.on(element, 'change', (e) => {
            env.setValue(name, value);
            watch.refresh();
            env.scan();
        });

        watch = env.watch(name, (newValue) => {
            element.checked = value === newValue;
        }, {readOnly: true});
    };


    function checkboxHandler(scope, element, name, env) {
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
                });
            }
        }

        env.fastBinding(scope, element, name, env);
    }

}
