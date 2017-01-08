/* library to work with DOM */
(function(){
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

    f$.isFunction = function(fn) {
        return (fn && Object.prototype.toString.call(fn) === '[object Function]')
    };

    f$.isObject = function(o) {
        return (o && Object.prototype.toString.call(o) === '[object Object]')
    };

    f$.isPromise = function(p) {
        return p && window.Promise && p instanceof window.Promise;
    };

    f$.isElement = function(el) {
        return el instanceof HTMLElement
    };

    f$.addClass = function(element, name) {
        if(element.classList) element.classList.add(name)
        else element.className += ' ' + name
    };

    f$.removeClass = function(element, name) {
        if(element.classList) element.classList.remove(name)
        else element.className = element.className.replace(new RegExp('(^| )' + name.split(' ').join('|') + '( |$)', 'gi'), ' ')
    };

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
        if(args.username || args.password || args.headers || args.data || !args.cache) return f$.rawAjax(args);

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
        var css = '@charset "UTF-8";[al-cloak],[hidden],.al-hide{display:none !important;}';
        var head = document.querySelectorAll('head')[0];

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
