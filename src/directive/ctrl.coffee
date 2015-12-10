
alight.d.al.ctrl =
    scope: 'isolate'
    global: false
    link: (scope, element, name, env) ->
        error = (e, title) ->
            alight.exceptionHandler e, title,
                name: name
                env: env
                scope: scope
                element: element
            return

        $ns = scope.$ns
        if $ns and $ns.ctrl
            fn = $ns.ctrl[name]
            if not fn and not $ns.inheritGlobal
                error '', 'Controller not found in $ns: ' + name
                return

        if not fn
            fn = alight.ctrl[name]
        
            if not fn and alight.d.al.ctrl.global
                fn = window[name]

        if fn
            try
                fn scope, element, name, env
            catch e
                error e, 'Error in controller: ' + name
        else
            error '', 'Controller not found: ' + name
        return
