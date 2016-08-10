
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
    } else {
        changeDetector = alight.ChangeDetector(data);
    }

    if(Array.isArray(input)) {
        for(let item of input)
            alight.bootstrap(item, changeDetector);
        return;
    }

    if(typeof(input) === 'string') {
        let elements = document.querySelectorAll(input);
        for(let element of elements)
            alight.bootstrap(element, changeDetector);
        return;
    }

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
                attachDirective: {'al-ctrl': ctrlName}
            }
        }

        alight.bind(changeDetector, input, option);
        return changeDetector;
    } else {
        alight.exceptionHandler('Error in bootstrap', 'Error input arguments', {
            input: input
        })
    }
}