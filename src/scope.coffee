
alight.Scope = (option) ->
    option = option or {}
    # customScope, childFromChangeDetector, $parent

    if option.customScope
        scope = option.customScope
        if not scope.$scan
            for name of Scope::
                scope[name] = Scope::[name]
    else
        scope = new Scope

    if option.childFromChangeDetector
        childCD = option.childFromChangeDetector.new scope
        scope.$rootChangeDetector = childCD
    else
        scope.$rootChangeDetector = alight.ChangeDetector scope

    if option.$parent
        scope.$parent = option.$parent

    scope.$changeDetector = null
    scope

Scope = ->

alight.core.Scope = Scope

Scope::$watch = (name, callback, option) ->
    if option and option.changeDetector
        cd = option.changeDetector
    else
        cd = @.$changeDetector
    if not cd and not @.$rootChangeDetector.children.length  # no child scopes
        cd = @.$rootChangeDetector
    if cd
        return cd.watch name, callback, option
    else
        alight.exceptionHandler '', 'You can do $watch during binding only: ' + name,
            name: name
            option: option
            scope: @
    return

Scope::$scan = (option) ->
    cd = @.$rootChangeDetector
    cd.scan option

Scope::$setValue = (name, value) ->
    cd = @.$rootChangeDetector
    cd.setValue name, value
    return

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
    return

Scope::$new = () ->
    if not @.$changeDetector
        throw 'No change detector'
    alight.Scope
        $parent: @
        childFromChangeDetector: @.$changeDetector
