
alight.bootstrap = function(input, data) {
    if(!input) {
        alight.bootstrap('[al-app]');
        alight.bootstrap('[al\\:app]');
        alight.bootstrap('[data-al-app]');
        return;
    }

    var changeDetector;
    if(input instanceof alight.core.ChangeDetector) {
        changeDetector = input;
        input = data;
    } else if(data instanceof alight.core.ChangeDetector) {
        changeDetector = data;
    } else if(f$.isFunction(data)) {
        var scope = {};
        changeDetector = alight.ChangeDetector(scope);
        data.call(changeDetector, scope);
    } else if(data) {
        changeDetector = alight.ChangeDetector(data);
    }

    if(Array.isArray(input)) {
        let result;
        for(let item of input)
            result = alight.bootstrap(item, changeDetector);
        return result;
    }

    if(typeof(input) === 'string') {
        let result;
        let elements = document.querySelectorAll(input);
        for(let element of elements)
            result = alight.bootstrap(element, changeDetector);
        return result;
    }

    if(!changeDetector) changeDetector = alight.ChangeDetector();

    if(f$.isElement(input)) {
        var ctrlKey, ctrlName;
        for(ctrlKey of ['al-app', 'al:app', 'data-al-app']) {
            ctrlName = input.getAttribute(ctrlKey);
            input.removeAttribute(ctrlKey);
            if(ctrlName) break;
        }

        var option;
        if(ctrlName) {
            option = {
                skip_attr: [ctrlKey],
                attachDirective: {}
            }
            if(alight.d.al.ctrl)
                option.attachDirective['al-ctrl'] = ctrlName;
            else
                option.attachDirective[ctrlName + '!'] = '';
        }

        alight.bind(changeDetector, input, option);
        return changeDetector;
    };

    alight.exceptionHandler('Error in bootstrap', 'Error input arguments', {
        input: input
    })
}