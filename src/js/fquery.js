/* library to work with DOM */
(function(){
    f$.text = function(element, text) {
        if(arguments.length === 2) {
            if(element.textContent !== undefined) element.textContent = text;
            else element.innerText = text
        } else {
            return element.textContent || element.innerText;
        }
    };

    f$.before = function(base, elm) {
        var parent = base.parentNode;
        parent.insertBefore(elm, base)
    };

    f$.after = function(base, elm) {
        var parent = base.parentNode;
        var n = base.nextSibling;
        if(n) parent.insertBefore(elm, n)
        else parent.appendChild(elm)
    };

    f$.remove = function(elm) {
        var parent = elm.parentNode;
        if(parent) parent.removeChild(elm)
    };

    // on / off
    f$.on = function(element, event, callback) {
        element.addEventListener(event, callback, false)
    };
    f$.off = function(element, event, callback) {
        element.removeEventListener(event, callback, false)
    };        

    f$.find = function(element, selector) {
        return element.querySelectorAll(selector)
    };

    f$.attr = function(element, name, value) {
        if(arguments.length===2)
            return element.getAttribute(name)
        else
            element.setAttribute(name, value)
    };

    f$.removeAttr = function(element, name) {
        element.removeAttribute(name)
    };        

    //    # $.isFunction
    f$.isFunction = function(fn) {
        var gt = {};
        return (fn && gt.toString.call(fn) === '[object Function]')
    };

    f$.isObject = function(fn) {
        var gt = {};
        return (fn && gt.toString.call(fn) === '[object Object]')
    };

    f$.isArray = function(obj) {
        return obj instanceof Array;
    };

    f$.isElement = function(el) {
        return el instanceof HTMLElement
    };

    f$.prop = function(element, name, value) {
        if(arguments.length===2) return element[name]
        else element[name] = value
    };

    f$.addClass = function(element, name) {
        if(element.classList) element.classList.add(name)
        else element.className += ' ' + name
    };

    f$.removeClass = function(element, name) {
        if(element.classList) element.classList.remove(name)
        else element.className = element.className.replace(new RegExp('(^| )' + name.split(' ').join('|') + '( |$)', 'gi'), ' ')
    };

    f$.show = function(element) {
        f$.removeClass(element, 'al-hide')
    };

    f$.hide = function(element) {
        f$.addClass(element, 'al-hide')
    };

    f$.getAttributes = function (element) {
        var attr, r = {}, attrs = element.attributes;
        for (var i=0, l=attrs.length; i<l; i++) {
            attr = attrs.item(i)
            r[attr.nodeName] = attr.value;
        }
        return r
    };

    f$.ready = (function() {
        var callbacks = [];
        var ready = false;
        function onReady() {
            ready = true;
            f$.off(document, 'DOMContentLoaded', onReady);
            for(var i=0;i<callbacks.length;i++)
                callbacks[i]();
            callbacks.length = 0;
        };
        f$.on(document, 'DOMContentLoaded', onReady);
        return function(callback) {
            if(ready) callback();
            else callbacks.push(callback)
        }
    })();

    f$.rawAjax = function(args) {
        var request = new XMLHttpRequest();
        request.open(args.type || 'GET', args.url, true, args.username, args.password);
        for(var i in args.headers) request.setRequestHeader(i, args.headers[i]);

        if(args.success) {
            request.onload = function() {
                if (request.status >= 200 && request.status < 400){
                    args.success(request.responseText);
                } else {
                    if(args.error) args.error();
                }
            }
        }
        if(args.error) request.onerror = args.error;

        request.send(args.data || null);
    };

    /*
        ajax
            cache
            type
            url
            success
            error
            username
            password
            data
            headers
    */
    f$.ajaxCache = {};
    f$.ajax = function(args) {
        if(args.username || args.password || args.headers || args.data || !args.cache) return rawAjax(args);

        // cache
        var queryType = args.type || 'GET';
        var cacheKey = queryType + ':' + args.url;
        var d = f$.ajaxCache[cacheKey];
        if(!d) f$.ajaxCache[cacheKey] = d = {callback: []};  // data
        if(d.result) {
            if(args.success) args.success(d.result);
            return
        }
        d.callback.push(args);
        if(d.loading) return;
        d.loading = true;
        f$.rawAjax({
            type: queryType,
            url: args.url,
            success: function(result) {
                d.loading = false
                d.result = result;
                for(var i=0;i<d.callback.length;i++)
                    if(d.callback[i].success) d.callback[i].success(result)
                d.callback.length = 0;
            },
            error: function() {
                d.loading = false
                for(var i=0;i<d.callback.length;i++)
                    if(d.callback[i].error) d.callback[i].error()
                d.callback.length = 0;
            }
        })
    };

    // append classes
    (function(){
        var css = '@charset "UTF-8";[al-cloak],.al-hide{display:none !important;}';
        var head = f$.find(document, 'head')[0];

        var s = document.createElement('style');
        s.setAttribute('type', 'text/css');
        if (s.styleSheet) {  // IE
            s.styleSheet.cssText = css;
        } else {
            s.appendChild(document.createTextNode(css));
        }
        head.appendChild(s);
    })();

})();
