
alight.text.bindonce = (callback, expression, scope, env) ->
    env.finally scope.$eval expression

alight.text.oneTimeBinding = (callback, expression, scope, env) ->
    setted = false
    w = scope.$watch expression, (value) ->
        if value is undefined
            return
        if setted
            return
        setted = true
        scope.$scan ->
            w.stop()
        env.finally value
    ,
        init: true

dirs = alight.directives.al

dirs.debug =
    priority: 5000
    init: (element, name, scope) ->
        if name
            alight.debug = scope.$eval name
        else
            alight.debug = -1

dirs.text = (element, name, scope) ->
    init_value = ''
    self =
        start: ->
            self.watchModel()
            self.initDom()
        updateDom: (value) ->
            if (value is undefined) or (value is null)
                value = ''
            f$.text element, value
        watchModel: ->
            exp = scope.$watch name, self.updateDom, { readOnly:true }
            init_value = exp.value
        initDom: ->
            self.updateDom init_value


dirs.value = (element, variable, scope) ->
    init_value = null
    self =
        changing: false
        onDom: ->
            f$.on element, 'input', self.updateModel
            f$.on element, 'change', self.updateModel
            scope.$watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'input', self.updateModel
            f$.off element, 'change', self.updateModel
        updateModel: ->
            alight.nextTick ->
                value = f$.val element
                self.changing = true
                scope.$setValue variable, value
                scope.$scan ->
                    self.changing = false
        watchModel: ->
            exp = scope.$watch variable, self.updateDom, { readOnly:true }
            init_value = exp.value
        updateDom: (value) ->
            if self.changing
                return
            value ?= ''
            f$.val element, value
        initDom: ->
            self.updateDom init_value
        start: ->
            self.onDom()
            self.watchModel()
            self.initDom()


click_maker = (event) ->
    priority: 10
    init: (element, name, scope, env) ->
        self =
            callback: scope.$compile name,
                no_return: true
                noBind: true
            start: ->
                self.onDom()
                self.stop = env.takeAttr 'al-click-stop'
            onDom: ->
                f$.on element, event, self.doCallback
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, event, self.doCallback
            doCallback: (e) ->
                if not self.stop
                    e.preventDefault()
                    e.stopPropagation()

                if f$.attr element, 'disabled'
                    return

                try
                    self.callback scope
                catch e
                    alight.exceptionHandler e, 'al-click, error in expression: ' + name,
                        name: name
                        scope: scope
                        element: element

                if self.stop and scope.$eval self.stop
                    e.preventDefault()
                    e.stopPropagation()

                scope.$scan()

dirs.click = click_maker 'click'
dirs.dblclick = click_maker 'dblclick'


dirs.submit = (element, name, scope) ->
    self =
        callback: scope.$compile name,
            no_return: true
            noBind: true
        start: ->
            self.onDom()
        onDom: ->
            f$.on element, 'submit', self.doCallback
            scope.$watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'submit', self.doCallback
        doCallback: (e) ->
            e.preventDefault()
            e.stopPropagation()
            try
                self.callback scope
            catch e
                alight.exceptionHandler e, 'al-submit, error in expression: ' + name,
                    name: name
                    scope: scope
                    element: element
            scope.$scan()


dirs.controller =
    priority: 500
    restrict: 'AE'
    init: (element, name, scope, env) ->
        self =
            owner: true
            start: ->
                newScope = scope.$new()
                self.callController newScope
                alight.applyBindings newScope, element, { skip_attr:env.skippedAttr() }
            callController: (newScope) ->
                if name
                    d = name.split ' as '
                    ctrl = alight.getController d[0], newScope
                    if d[1]
                        newScope[d[1]] = new ctrl(newScope)
                    else
                        ctrl newScope
        self


dirs.checked =
    priority: 100
    init: (element, name, scope) ->
        init_value = false
        self =
            changing: false
            start: ->
                self.onDom()
                self.watchModel()
                self.initDom()
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                self.changing = true
                scope.$setValue name, value
                scope.$scan ->
                    self.changing = false
            watchModel: ->
                w = scope.$watch name, self.updateDom, { readOnly:true }
                init_value = !!w.value
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', !!value
            initDom: ->
                self.updateDom init_value


dirs.radio =
    priority: 10
    init: (element, name, scope, env) ->
        init_value = false
        self =
            changing: false
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
                self.initDom()
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = scope.$eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                self.changing = true
                scope.$setValue name, self.value
                scope.$scan ->
                    self.changing = false
            watchModel: ->
                w = scope.$watch name, self.updateDom,
                    readOnly: true
                init_value = w.value
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', value is self.value
            initDom: ->
                self.updateDom init_value


# al-css="class:exp"
dirs.class = dirs.css =
    priority: 30
    init: (element, exp, scope) ->
        self =
            start: ->
                self.parsLine()
                self.prepare()
            parsLine: ->
                self.list = list = []

                for e in exp.split ','
                    i = e.indexOf ':'
                    if i < 0
                        alight.exceptionHandler e, 'al-css, error in expression: ' + exp,
                            exp: exp
                            e: e
                            scope: scope
                            element: element
                    else
                        list.push
                            css: e[0..i-1].trim().split ' '
                            exp: e[i+1..].trim()
                null
            prepare: ->
                for item in self.list
                    color = do (item) ->
                        (value) ->
                            self.draw item, value

                    result = scope.$watch item.exp, color,
                        readOnly: true
                        init: true
                null
            draw: (item, value) ->
                if value
                    for c in item.css
                        f$.addClass element, c
                else
                    for c in item.css
                        f$.removeClass element, c


make_boif = (direct) ->
    self =
        priority: 700
        init: (element, exp, scope) ->
            value = scope.$eval exp
            if !value is direct
                f$.remove element
                { owner:true }

alight.directives.bo.if = make_boif true
alight.directives.bo.ifnot = make_boif false


dirs.if =
    priority: 700
    init: (element, name, scope, env) ->
        item = null
        child = null
        base_element = null
        top_element = null
        init_value = false

        self =
            direction: true
            owner: true
            start: ->
                self.prepare()
                self.watchModel()
                self.initUpdate()
            prepare: ->
                base_element = element
                top_element = f$.createComment " #{env.attrName}: #{name} "
                f$.before element, top_element
                f$.remove element
            updateDom: (value) ->
                if !value is self.direction
                    if not child
                        return
                    child.$destroy()
                    self.removeDom item
                    child = null
                    item = null
                else
                    if child
                        return
                    item = f$.clone base_element
                    self.insertDom top_element, item
                    child = scope.$new()
                    alight.applyBindings child, item, { skip_attr:env.skippedAttr() }
            watchModel: ->
                w = scope.$watch name, self.updateDom, { readOnly:true }
                init_value = !!w.value
            initUpdate: ->
                self.updateDom init_value
            removeDom: (element) ->
                f$.remove element
            insertDom: (base, element) ->
                f$.after base, element


dirs.ifnot =
    priority: 700
    init: (element, name, scope, env) ->
        dirs = alight.directives.al.if.init.apply @, arguments
        dirs.direction = false
        dirs


dirs.show = (element, exp, scope) ->
    init_value = false
    self =
        showDom: ->
            f$.show element
        hideDom: ->
            f$.hide element
        updateDom: (value) ->
            if value
                self.showDom()
            else
                self.hideDom()
        watchModel: ->
            w = scope.$watch exp, self.updateDom, { readOnly:true }
            init_value = w.value
        initDom: ->
            self.updateDom init_value
        start: ->
            self.watchModel()
            self.initDom()


dirs.hide = (element, exp, scope, env) ->
    self = alight.directives.al.show element, exp, scope, env
    self.updateDom = (value) ->
        if value
            self.hideDom()
        else
            self.showDom()
    self


dirs.app =
    priority: 2000
    init: ->
        { owner: true }

dirs.stop =
    priority: -10
    restrict: 'AE'
    init: ->
        { owner: true }

dirs.init = (element, exp, scope) ->
    try
        fn = scope.$compile exp,
            no_return: true
            noBind: true
        fn scope
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            element: element

    scope.$scan
        late: true


dirs.include =
    priority: 100
    init: (element, name, scope, env) ->
        child = null
        baseElement = null
        topElement = null
        activeElement = null
        initValue = null
        self =
            owner: true
            start: ->
                self.prepare()
                self.watchModel()
                self.initUpdate()
            prepare: ->
                baseElement = element
                topElement = f$.createComment " #{env.attrName}: #{name} "
                f$.before element, topElement
                f$.remove element
            loadHtml: (cfg) ->
                f$.ajax cfg
            removeBlock: ->
                if child
                    child.$destroy()
                    child = null
                if activeElement
                    self.removeDom activeElement
                    activeElement = null
            insertBlock: (html) ->
                activeElement = f$.clone baseElement
                f$.html activeElement, html
                self.insertDom topElement, activeElement
                child = scope.$new()
                alight.applyBindings child, activeElement, { skip_attr:env.skippedAttr() }                
            updateDom: (url) ->
                if not url
                    return self.removeBlock()
                self.loadHtml
                    cache: true
                    url: url
                    success: (html) ->
                        self.removeBlock()
                        self.insertBlock html
                    error: self.removeBlock
            removeDom: (element) ->
                f$.remove element
            insertDom: (base, element) ->
                f$.after base, element
            watchModel: ->
                w = scope.$watch name, self.updateDom,
                    readOnly: true
                initValue = w.value
            initUpdate: ->
                self.updateDom initValue

        self


dirs.html =
    priority: 100
    init: (element, name, scope, env) ->
        child = null
        setter = (html) ->
            if child
                child.$destroy()
                child = null
            if not html
                f$.html element, ''
                return
            f$.html element, html
            child = scope.$new()
            alight.applyBindings child, element, { skip_attr:env.skippedAttr() }

        r = scope.$watch name, setter, { readOnly:true }
        setter r.value

        return { owner: true }


alight.directives.bo.switch =
    priority: 500
    init: (element, name, scope, env) ->
        child = scope.$new()
        child.$switch =
            value: scope.$eval name
            on: false

        alight.applyBindings child, element, { skip_attr:env.skippedAttr() }

        { owner:true }


alight.directives.bo.switchWhen =
    priority: 500
    init: (element, name, scope) ->
        if scope.$switch.value != name
            f$.remove element
            return { owner:true }
        scope.$switch.on = true


alight.directives.bo.switchDefault =
    priority: 500
    init: (element, name, scope) ->
        if scope.$switch.on
            f$.remove element
            return { owner:true }
        null


dirs.src = (element, name, scope) ->
    setter = (value) ->
        if not value
            value = ''
        f$.attr element, 'src', value
    r = scope.$watchText name, setter, { readOnly:true }
    setter r.value


alight.directives.bo.src = (element, name, scope) ->
    value = scope.$evalText name
    if value
        f$.attr element, 'src', value


dirs.enable = (element, exp, scope) ->
    setter = (value) ->
        if value
            f$.removeAttr element, 'disabled'
        else
            f$.attr element, 'disabled', 'disabled'

    w = scope.$watch exp, setter, { readOnly:true }
    setter w.value


dirs.disable = (element, exp, scope) ->
    setter = (value) ->
        if value
            f$.attr element, 'disabled', 'disabled'
        else
            f$.removeAttr element, 'disabled'

    w = scope.$watch exp, setter, { readOnly:true }
    setter w.value


dirs.readonly = (element, exp, scope) ->
    setter = (value) ->
        f$.prop element, 'readOnly', !!value

    w = scope.$watch exp, setter, { readOnly:true }
    setter w.value


for key in ['keydown', 'keypress', 'keyup', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseup', 'focus', 'blur', 'change']
    do (key) ->
        dirs[key] = (element, exp, scope) ->
            self =
                start: ->
                    self.makeCaller()
                    self.onDom()
                makeCaller: ->
                    self.caller = scope.$compile exp,
                        no_return: true
                        noBind: true
                        input: ['$event']
                onDom: ->
                    f$.on element, key, self.callback
                    scope.$watch '$destroy', self.offDom
                offDom: ->
                    f$.off element, key, self.callback
                callback: (e) ->
                    try
                        self.caller scope, e
                    catch e
                        alight.exceptionHandler e, key + ', error in expression: ' + exp,
                            exp: exp
                            scope: scope
                            element: element
                    scope.$scan()


dirs.cloak = (element, name, scope, env) ->
    f$.removeAttr element, env.attrName
    if name
        f$.removeClass element, name


dirs.focused = (element, name, scope) ->
    init_value = false
    safe =
        changing: false
        updateModel: (value) ->
            if safe.changing
                return
            safe.changing = true
            scope.$setValue name, value
            scope.$scan ->
                safe.changing = false

        onDom: ->
            von = ->
                safe.updateModel true
            voff = ->
                safe.updateModel false
            f$.on element, 'focus', von
            f$.on element, 'blur', voff
            scope.$watch '$destroy', ->
                f$.off element, 'focus', von
                f$.off element, 'blur', voff

        updateDom: (value) ->
            if safe.changing
                return
            safe.changing = true
            if value
                f$.focus(element)
            else
                f$.blur(element)
            safe.changing = false

        watchModel: ->
            w = scope.$watch name, safe.updateDom, { readOnly:true }
            init_value = w.value

        initDom: ->
            safe.updateDom init_value

        start: ->
            safe.onDom()
            safe.watchModel()
            safe.initDom()


dirs.style = (element, name, scope) ->
    prev = {}
    setter = (style) ->
        for key, v of prev
            element.style[key] = ''

        prev = {}
        for k, v of style or {}
            key = k.replace /(-\w)/g, (m) ->
                m.substring(1).toUpperCase()
            prev[key] = v
            element.style[key] = v or ''

    scope.$watch name, setter,
        deep: true
        init: true


dirs.with = (element, name, scope, env) ->
    baseElement = null
    topElement = null
    child = null
    activeElement = null
    initValue = null
    self =
        owner: true
        start: ->
            self.prepare()
            self.watchModel()
            self.initUpdate()
        prepare: ->
            baseElement = element
            topElement = f$.createComment " #{env.attrName}: #{name} "
            f$.before element, topElement
            f$.remove element
        watchModel: ->
            w = scope.$watch name, (value) ->
                self.removeBlock()
                self.insertBlock value
            initValue = w.value
            scope.$watch '$destroy', ->
                self.removeBlock()
        removeBlock: ->
            if child
                child.$destroy()
                child = null
            if activeElement
                self.removeDom activeElement
                activeElement = null
        insertBlock: (value) ->
            if not f$.isObject value
                return
            activeElement = f$.clone baseElement
            self.insertDom topElement, activeElement
            child = alight.Scope
                prototype: value
                root: scope.$system.root
                attachParent: scope
            alight.applyBindings child, activeElement, { skip_attr:env.skippedAttr() }
        removeDom: (element) ->
            f$.remove element
        insertDom: (base, element) ->
            f$.after base, element
        initUpdate: ->
            self.insertBlock initValue
