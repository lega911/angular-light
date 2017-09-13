{
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
        'checkbox': null,
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

}
