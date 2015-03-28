
Scope = (conf) ->
    return @ if @ instanceof Scope
    conf = conf or {}

    if conf.prototype
        scope = conf.prototype

        for k, v of Scope::
            scope[k] = v
    else
        scope = new Scope()

    root = conf.root or alight.core.root
        useObserver: (alight.debug.useObserver or conf.useObserver) and alight.observer.support()
    scope.$system = root.node scope,
        keywords: ['$system', '$parent', '$ns']
    scope.$system.exIsRoot = true
    scope.$system.exChildren = []

    if scope.$system.ob
        scope.$system.ob.rootEvent = (key, value) ->
            for child in scope.$system.exChildren
                child.$$rebuildObserve key, value
            null
    scope

alight.Scope = Scope


Scope::$$rebuildObserve = (key, value) ->
    scope = @
    scope.$system.ob.reobserve key
    for child in scope.$system.exChildren
        child.$$rebuildObserve key, value
    scope.$system.ob.fire key, value


Scope::$new = (isolate) ->
    parent = @
    
    if isolate
        scope = alight.Scope
            root: parent.$system.root
    else
        if not parent.$system.exChildConstructor
            parent.$system.exChildConstructor = ->
            parent.$system.exChildConstructor:: = parent
        scope = new parent.$system.exChildConstructor

    scope.$system = parent.$system.root.node scope,
        keywords: ['$system', '$parent', '$ns']
    scope.$system.exChildren = []
    scope.$parent = parent

    if scope.$system.ob
        scope.$system.ob.rootEvent = (key, value) ->
            for child in scope.$system.exChildren
                child.$$rebuildObserve key, value
            null

    parent.$system.exChildren.push scope
    scope


###
$watch
    name:
        expression or function
        $any
        $destroy
        $finishBinding
        $finishScan
        $finishScanOnce
    callback:
        function
    option:
        isArray (is_array)
        readOnly
        init
        deep

###

Scope::$watch = (name, callback, option) ->
    option = option or {}
    if option is true
        option =
            isArray: true
    @$system.watch name, callback, option


###
    cfg:
        no_return   - method without return (exec)
        string      - method will return result as string
        stringOrOneTime
        input   - list of input arguments
        full    - full response
        noBind  - get function without bind to scope
        rawExpression

###

Scope::$compile = (src, option) ->
    @$system.compile src, option


Scope::$eval = (exp) ->
    @$compile(exp, {noBind: true})(@)


Scope::$getValue = (name) ->
    @$eval name


Scope::$setValue = (name, value) ->
    fn = @$compile name + ' = $value',
        input: ['$value']
        no_return: true
        noBind: true
    fn @, value


Scope::$destroy = () ->
    scope = this
    node = scope.$system
    root = node.root

    if not scope.$system.exIsRoot
        removeItem scope.$parent.$system.exChildren, scope

    for child in node.exChildren.slice()
        child.$destroy()

    node.destroy()
    if scope.$system.exIsRoot
        root.destroy()

    #scope.$system = null


    ###

    # fire callbacks
    for cb in node.destroy_callbacks
        cb scope
    node.destroy_callbacks.length = 0

    # remove from parent
    if scope.$parent
        removeItem scope.$parent.$system.children, scope

    # remove watch
    scope.$parent = null
    node.watchers = {}
    node.watchList = []

    ###


Scope::$scanAsync = (callback) ->
    @$scan
        late: true
        callback: callback


Scope::$scan = (option) ->
    if f$.isFunction option
        option =
            callback: option
    else
        option = option or {}
    @$system.root.scan option
