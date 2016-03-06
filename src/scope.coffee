
alight.hooks.scope = []

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

    if alight.hooks.scope.length
        self =
            scope: scope
            changeDetector: scope.$rootChangeDetector
        for d in alight.hooks.scope
            d.fn.call self
        scope = self.scope
    scope

Scope = ->

alight.core.Scope = Scope

getCDFromScope = (scope, name, option) ->
    if option and option.changeDetector
        return option.changeDetector
    else
        cd = scope.$changeDetector
    if not cd and not scope.$rootChangeDetector.children.length  # no child scopes
        cd = scope.$rootChangeDetector
    if cd
        return cd
    alight.exceptionHandler '', 'You can do $watch during binding only: ' + name,
        name: name
        option: option
        scope: scope
    return

Scope::$watch = (name, callback, option) ->
    cd = getCDFromScope @, name, option
    if cd
        return cd.watch name, callback, option

Scope::$watchGroup = (keys, callback) ->
    cd = getCDFromScope @, ''+keys
    if cd
        cd.watchGroup keys, callback

Scope::$scan = (option) ->
    cd = @.$rootChangeDetector
    cd.scan option

Scope::$setValue = (name, value) ->
    cd = @.$rootChangeDetector
    cd.setValue name, value
    return

Scope::$getValue = (name) ->
    cd = @.$rootChangeDetector
    cd.getValue name

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
