
alight.hooks.scope = []

if window.Map
    cd_mapRoot = new Map()
    cd_map = new Map()
    cd_setRoot = (scope, cd) ->
        cd_mapRoot.set scope, cd
    cd_getRoot = (scope) ->
        cd_mapRoot.get scope
    cd_getActive = (scope) ->
        cd = cd_map.get scope
        if cd
            cd
        else
            root = cd_getRoot scope
            if root.children.length
                null
            else
                root
    cd_setActive = (scope, cd) ->
        cd_map.set scope, cd
else
    cd_setRoot = (scope, cd) ->
        scope.$rootChangeDetector = cd
    cd_getRoot = (scope) ->
        scope.$rootChangeDetector
    cd_getActive = (scope) ->
        if scope.$changeDetector
            scope.$changeDetector
        else
            if scope.$rootChangeDetector.children.length
                return null
            return scope.$rootChangeDetector
    cd_setActive = (scope, cd) ->
        scope.$changeDetector = cd

scopeWrap = (cd, fn) ->
    cd_setActive cd.scope, cd
    try
        fn()
    finally
        cd_setActive cd.scope, null

alight.core.cd_setRoot = cd_setRoot
alight.core.cd_getRoot = cd_getRoot
alight.core.cd_getActive = cd_getActive
alight.core.cd_setActive = cd_setActive
alight.core.scopeWrap = scopeWrap

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

    if option.changeDetector
        childCD = option.changeDetector
    else if option.childFromChangeDetector
        childCD = option.childFromChangeDetector.new scope
    else
        childCD = alight.ChangeDetector scope
    cd_setRoot scope, childCD

    if option.$parent
        scope.$parent = option.$parent

    cd_setActive scope, null

    if alight.hooks.scope.length
        self =
            scope: scope
            changeDetector: childCD
        for d in alight.hooks.scope
            d.fn.call self
        scope = self.scope

    if option.returnChangeDetector
        childCD
    else
        scope

Scope = ->

alight.core.Scope = Scope

Scope::$watch = (name, callback, option) ->
    cd = cd_getActive @
    if cd
        cd.watch name, callback, option
    else
        alight.exceptionHandler '', 'You can do scope.$watch during binding only, use env.watch instead: ' + name,
            name: name
            option: option
            scope: @

Scope::$watchGroup = (keys, callback) ->
    cd = cd_getActive @
    if cd
        cd.watchGroup keys, callback
    else
        alight.exceptionHandler '', 'You can do scope.$watchGroup during binding only, use env.watchGroup instead: ' + name,
            keys: keys
            option: option
            scope: @

Scope::$scan = (option) ->
    cd_getRoot(@).scan option

Scope::$setValue = (name, value) ->
    cd_getRoot(@).setValue name, value
    return

Scope::$getValue = (name) ->
    cd_getRoot(@).getValue name

Scope::$eval = (exp) ->
    cd_getRoot(@).eval exp

Scope::$compile = (exp, option) ->
    cd_getRoot(@).compile exp, option

Scope::$destroy = ->
    cd_getRoot(@).destroy()
    return

Scope::$new = () ->
    cd = cd_getActive @
    if not cd
        throw 'No change detector'
    alight.Scope
        $parent: @
        childFromChangeDetector: cd

Scope::$watchText = (expression, callback, option) ->
    cd = cd_getActive @
    if cd
        cd.watchText expression, callback, option
    else
        alight.exceptionHandler '', 'You can do $watchText during binding only, use env.watchText instead: ' + expression,
            expression: expression
            option: option
            scope: @
        return
