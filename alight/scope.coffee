###
    Scope
        prototype
        parent
        attachParent
        root

###
Scope = (conf) ->
    return @ if @ instanceof Scope
    conf = conf or {}

    if conf.prototype
        scope = conf.prototype
        if not scope.$new
            if Object.setPrototypeOf
                proto = scope
                objectProto = ({}).__proto__
                while proto.__proto__ isnt objectProto
                    proto = proto.__proto__

                Object.setPrototypeOf proto, Scope.prototype
            else
                for k, v of Scope::
                    scope[k] = v
    else
        scope = new Scope()

    if conf.parent
        if conf.root
            throw 'Conflict new Scope, root and parent together'
        parent = conf.parent
        if not parent.$system.exChildConstructor
            parent.$system.exChildConstructor = ->
            parent.$system.exChildConstructor:: = parent
        scope = new parent.$system.exChildConstructor
        root = parent.$system.root
        isRoot = false

    if conf.root
        root = conf.root
        isRoot = false
    if not root
        root = alight.core.root()
        isRoot = true

    scope.$system = root.node scope,
        keywords: ['$system', '$parent', '$ns']
    scope.$system.exIsRoot = isRoot
    scope.$system.exChildren = []

    if conf.attachParent
        scope.$parent = conf.attachParent
        conf.attachParent.$system.exChildren.push scope

    scope

alight.Scope = Scope


###
    isolate:
        true / false / 'root'
###
Scope::$new = (isolate) ->
    parent = @
    
    if isolate is 'root'
        scope = alight.Scope
            attachParent: parent
    else if isolate
        scope = alight.Scope
            root: parent.$system.root
            attachParent: parent
    else
        scope = alight.Scope
            parent: parent
            attachParent: parent

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
        isArray
        readOnly
        init
        deep

###

Scope::$watch = (name, callback, option) ->
    option = option or {}
    if option is true
        option =
            isArray: true
    @.$system.watch name, callback, option


###
    cfg:
        no_return   - method without return (exec)
        string      - method will return result as string
        input   - list of input arguments
        full    - full response
        rawExpression

###

Scope::$compile = (src, option) ->
    alight.utils.compile.expression(src, option).fn


Scope::$eval = (exp) ->
    fn = @.$compile exp
    fn @


Scope::$getValue = (name) ->
    @.$eval name


Scope::$setValue = (name, value) ->
    fn = @.$compile name + ' = $value',
        input: ['$value']
        no_return: true
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


Scope::$scanAsync = (callback) ->
    @.$scan
        late: true
        callback: callback


Scope::$scan = (option) ->
    if f$.isFunction option
        option =
            callback: option
    else
        option = option or {}
    @.$system.root.scan option
