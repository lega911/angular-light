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
            selectHandler(scope, element, value, env);
        } else {
            componentHandler(scope, element, value, env);
        }
    };


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
    };

    function selectHandler(scope, element, name, env) {
        let cd = env.new();

        let value = null;
        let values = {};
        let index = 0;

        cd.$select = {
            add: (value) => {
                index++;
                values[index] = value;
                updateValue();
                return index;
            },
            remove: (index) => {
                delete values[index];
                updateValue();
            }
        };

        env.on(element, 'change', () => {
            value = event.target.value;
            if(index) value = values[value];
            env.setValue(name, value);
            watch.refresh();
            env.scan();
        });

        function updateValue() {
            for(let i in values) {
                if(values[i] === value) {
                    element.value = i;
                    return
                }
            }
            element.selectedIndex = -1;
        };

        let watch = env.watch(name, (newValue) => {
            value = newValue;
            if(index) updateValue();
            else element.value = value;
        });
        env.bind(cd);
    };

    alight.d.al.model.selectHandler = (scope, element, name, env) => {
        let lvl = 4;
        let $select = null;
        let p = env.changeDetector;
        while(lvl-- > 0) {
            if(p.$select) {
                $select = p.$select;
                break;
            }
            p = p.parent;
        }
        if(!$select) throw 'Select model not found';

        let value = env.getValue(name);
        let index = $select.add(value);
        element.value = index;

        env.watch('$destroy', () => {
            $select.remove(index);
        });
    };


    function componentHandler(scope, element, name, env) {
        env.on(element, 'input', (e) => {
            if(!e.component) return;
            env.setValue(name, e.value);
            env.scan();
        });
    }
}