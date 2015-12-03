
Scope = ->
    @.$rootChangeDetector = alight.ChangeDetector @
    @.$changeDetector = null
    @

alight.Scope = (data) ->
    if data
        Object.setPrototypeOf data, Scope.prototype
        Scope.call data
        return data
    new Scope

alight.core.Scope = Scope

Scope::$watch = (name, callback, option) ->
    cd = @.$changeDetector
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
