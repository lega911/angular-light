
Scope = (option) ->
    if @ instanceof Scope
        return @

    option = option or {}

    if option.data
        scope = option.data
        if Object.setPrototypeOf
            Object.setPrototypeOf scope, Scope.prototype
        else
            for name of Scope::
                scope[name] = Scope::[name]
    else
        scope = new Scope

    if option.changeDetector isnt undefined
        scope.$rootChangeDetector = option.changeDetector
    else
        scope.$rootChangeDetector = alight.ChangeDetector scope
    scope.$changeDetector = null
    scope

alight.Scope = Scope

alight.core.Scope = Scope

Scope::$watch = (name, callback, option) ->
    if option and option.root
        cd = @.$rootChangeDetector
    else
        cd = @.$changeDetector
        if not cd and not @.$rootChangeDetector.children.length  # no child scopes
            cd = @.$rootChangeDetector
    if not cd
        throw 'no Change Detector in scope'
    cd.watch name, callback, option

Scope::$scan = (option) ->
    cd = @.$rootChangeDetector
    cd.scan option

Scope::$setValue = (name, value) ->
    cd = @.$rootChangeDetector
    cd.setValue name, value

Scope::$getValue = (name, value) ->
    cd = @.$rootChangeDetector
    cd.getValue name, value

Scope::$eval = (exp) ->
    cd = @.$rootChangeDetector
    cd.eval exp

Scope::$compile = (exp, option) ->
    cd = @.$rootChangeDetector
    cd.compile exp, option

Scope::$destroy = ->
    cd = @.$rootChangeDetector
    cd.destroy()

Scope::$new = () ->
    scope = new Scope
        changeDetector: null
    scope.$rootChangeDetector = @.$rootChangeDetector.new scope
    scope.$parent = @
    scope
