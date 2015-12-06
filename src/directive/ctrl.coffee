
alight.d.al.ctrl =
    scope: 'isolate'
    global: true
    link: (scope, element, name, env) ->
        $ns = scope.$ns
        if $ns and $ns.ctrl
            fn = $ns.ctrl[name]
            if not fn and not $ns.inheritGlobal
                alight.exceptionHandler '', 'Controller not found in $ns: ' + name,
                    name: name
                    env: env
                    scope: scope
                    element: element
                return

        if not fn
            fn = alight.ctrl[name]
        
            if not fn and alight.d.al.ctrl.global
                fn = window[name]

        if fn
            fn scope, element, name, env
            null
        else
            alight.exceptionHandler '', 'Controller not found: ' + name,
                name: name
                env: env
                scope: scope
                element: element
