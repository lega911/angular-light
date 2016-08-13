
alight.d.al.ctrl =
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

                    if not fn and alight.option.globalController
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

                    childScope = new Controller
                else
                    childScope = {}

                childScope.$parent = scope
                childCD = env.changeDetector.new childScope

                try
                    if fn
                        ChildEnv = (cd) ->
                            @
                        ChildEnv:: = env
                        childEnv = new ChildEnv
                        childEnv.changeDetector = childCD
                        childEnv.parentChangeDetector = env.changeDetector

                        scopeWrap childCD, ->
                            fn.call childScope, childScope, element, name, childEnv
                catch e
                    error e, 'Error in controller: ' + name
                alight.bind childCD, element,
                    skip_attr: env.skippedAttr()
                return
