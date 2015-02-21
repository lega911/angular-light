
alight.animate = animate = {}

animate.active = true
animate.namespace = 'al'


###
    element
    conf
        callback
        start: add[], remove[]
        process: add[], remove[]
        finish: add[], remove[]
###
animate.perform = do ->
    tolist = (x) ->
        if not x
            return []
        if f$.isArray x
            return x
        [x]

    (el, conf) ->
        data = alight.utilits.dataByElement(el, 'animate')
        if data.prev
            data.prev.finish()

        apply = (d) ->
            if not d
                return
            for n in tolist d.add
                f$.addClass el, n
            for n in tolist d.remove
                f$.removeClass el, n
            null

        data.prev = prev =
            finish: ->
                data.prev = null
                prev.finish = null

                apply conf.finish
                if conf.callback
                    conf.callback()

        apply conf.start
        alight.nextTick ->
            onTransition el, ->
                if prev.finish
                    prev.finish()
            apply conf.process


animate.show = (el, callback) ->
    animate.perform el,
        callback: callback
        start:
            add: "#{animate.namespace}-hide-remove"
            remove: "al-hide"
        process:
            add: "#{animate.namespace}-hide-remove-active"
        finish:
            remove: ["#{animate.namespace}-hide-remove", "#{animate.namespace}-hide-remove-active"]


animate.hide = (el, callback) ->
    animate.perform el,
        callback: callback
        start:
            add: "#{animate.namespace}-hide-add"
        process:
            add: "#{animate.namespace}-hide-add-active"
        finish:
            add: "al-hide"
            remove: ["#{animate.namespace}-hide-add", "#{animate.namespace}-hide-add-active"]


animate.enter = (el, callback) ->
    animate.perform el,
        callback: callback
        start:
            add: "#{animate.namespace}-enter"
        process:
            add: "#{animate.namespace}-enter-active"
        finish:
            remove: ["#{animate.namespace}-enter", "#{animate.namespace}-enter-active"]


animate.leave = (el, callback) ->
    animate.perform el,
        callback: callback
        start:
            add: "#{animate.namespace}-leave"
        process:
            add: "#{animate.namespace}-leave-active"


animate.$classExists = (css) ->
    # document.styleSheets[1].rules[0].selectorText
    for style in document.styleSheets
        if not style.rules
            continue
        for rule in style.rules
            t = ' ' + rule.selectorText + ','
            if t.indexOf(' ' + css + ',') >= 0
                return true
    return false


onTransition = do ->
    transitionEvent = do ->
        el = document.createElement 'div'
        transitions = {
            'transition':'transitionend',
            'OTransition':'oTransitionEnd',
            'MozTransition':'transitionend',
            'WebkitTransition':'webkitTransitionEnd'
        }

        for k, v of transitions
            if el.style[k] isnt undefined
                return v
        null

    (el, callback) ->
        dur = window.getComputedStyle(el).transitionDuration
        dur = parseFloat(dur) * 1000 + 100

        fn = ->
            clearTimeout t
            el.removeEventListener transitionEvent, fn, false
            callback el
        el.addEventListener transitionEvent, fn, false
        t = setTimeout fn, dur


checkClass = (env, suffix) ->
    className = env.takeAttr('class')
    if className
        for n in className.split ' '
            if animate.$classExists ".#{n}.#{animate.namespace}-#{suffix}"
                return true
    false


# al-show/al-hide
do ->
    dshow = alight.directives.al.show
    alight.directives.al.show = (el, exp, scope, env) ->
        dir = dshow.apply @, arguments

        if animate.active and checkClass env, 'hide-remove'
            dir.showDom = ->
                animate.show el
        
            dir.hideDom = ->
                animate.hide el
        dir


# al-repeat
do ->
    rinit = alight.directives.al.repeat.init
    alight.directives.al.repeat.init = (el, exp, scope, env) ->
        dir = rinit.apply @, arguments

        if animate.active and checkClass env, 'enter'
            dir.rawUpdateDom = (removes, inserts) ->
                for e in removes
                    do (el=e) ->
                        animate.leave el, ->
                            f$.remove el

                for it in inserts
                    f$.after it.after, it.element
                    animate.enter it.element
        dir


# al-include
do ->
    rinit = alight.directives.al.include.init
    alight.directives.al.include.init = (el, exp, scope, env) ->
        dir = rinit.apply @, arguments

        if animate.active and checkClass env, 'enter'
            dir.removeDom = (element) ->
                animate.leave element, ->
                    f$.remove element
            dir.insertDom = (base, element) ->
                f$.after base, element
                animate.enter element
        dir


# al-if/al-ifnot
do ->
    rinit = alight.directives.al.if.init
    alight.directives.al.if.init = (el, exp, scope, env) ->
        dir = rinit.apply @, arguments

        if animate.active and checkClass env, 'enter'
            dir.removeDom = (element) ->
                animate.leave element, ->
                    f$.remove element
            dir.insertDom = (base, element) ->
                f$.after base, element
                animate.enter element
        dir
