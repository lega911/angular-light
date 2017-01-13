
alight.d.al.checked = function(scope, element, name, env) {
    env.fastBinding = true;

    let updateDOM, watch, opt = {};

    function takeAttr(name, attrName) {
        let text = env.takeAttr(attrName);
        if(text) {
            opt[name] = text;
            return true;
        } else {
            let exp = env.takeAttr(':' + attrName) || env.takeAttr('al-attr.' + attrName);
            if(exp) {
                env.watch(exp, (value) => {
                    opt[name] = value;
                    updateDOM();
                });
                return true;
            }
        }
    }

    if(takeAttr('value', 'value')) {
        let array = null;
        updateDOM = function() {
            element.checked = array && array.indexOf(opt.value) >= 0;
            return '$scanNoChanges';
        };

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
    } else {
        let value;
        opt.true = true;
        opt.false = false;

        takeAttr('true', 'true-value');
        takeAttr('false', 'false-value');

        updateDOM = function() {
            element.checked = value === opt.true;
            return '$scanNoChanges';
        };

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