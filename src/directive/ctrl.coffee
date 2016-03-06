
alight.d.al.ctrl =
    global: false
    stopBinding: true
    priority: 500
    link: (scope, element, name, env) ->
        error = (e, title) ->
            alight.exceptionHandler e, title,
                name: name
                env: env
                scope: scope
                element: element
            return

        self =
            getController: (name) ->
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

                if not fn
                    error '', 'Controller not found: ' + name
                fn

            start: ->
                if name
                    fn = self.getController name
                    if not fn
                        return
                else
                    fn = null

                if fn and Object.keys(fn::).length  # class
                    Controller = ->

                    for k, v of Scope::
                        Controller::[k] = v

                    for k, v of fn::
                        Controller::[k] = v

                    childScope = alight.Scope
                        $parent: scope
                        customScope: new Controller
                        childFromChangeDetector: env.changeDetector
                else
                    childScope = alight.Scope
                        $parent: scope
                        childFromChangeDetector: env.changeDetector

                try
                    if fn
                        childScope.$changeDetector = childScope.$rootChangeDetector
                        fn.call childScope, childScope, element, name, env
                        childScope.$changeDetector = null
                catch e
                    error e, 'Error in controller: ' + name
                alight.bind childScope, element,
                    skip_attr: env.skippedAttr()
                return
