
window.ttDOM = (html) ->
    dom = document.createElement 'div'
    dom.innerHTML = html
    dom


window.ttGetText = (el) ->
    result = el.textContent
    if typeof(result) isnt 'string'
        result = el.innerText
    result = result.replace /\s+/g, ' '
    result.trim()

window.f$_attr = (el, name, value) ->
    if arguments.length is 3
        el.setAttribute name, value
    else
        el.getAttribute name

window.f$_find = (el, q) ->
    el.querySelectorAll q


stat =
    started: 0
    ok: 0
    error: 0
    bStarted: 0
    bFinished: 0

testList = []


printTotals = ->
    msg = "Started #{stat.started}, Ok #{stat.ok}, Error #{stat.error}"
    if stat.error or stat.started isnt stat.ok
        console.error msg
    else
        console.log msg
    stat


to = setTimeout ->
    console.error 'timeout 4 sec'
    printTotals()
    for t in testList
        console.error 'opened UT:', t.title
, 4000


onClose = ->
    if stat.bStarted isnt stat.bFinished
        return
    printTotals()
    clearTimeout to


do ->
    stat.bStarted++;
    $ ->
        stat.bFinished++;
        onClose()


Timeout = ->
    list = []
    add: (delay, callback) ->
        list.push [delay, callback]
    next: ->
        if not list.length
            return false
        min = Infinity
        active = null
        for it in list
            if it[0] < min
                active = it
                min = it[0]
        list.splice list.indexOf(active), 1
        delay = active[0]
        for it in list
            it[0] -= delay
        active[1]()
        true


window.Test = do ->
    codes = {}
    filterByCode = document.location.hash[1..]
    (title, uniqCode) ->
        if not uniqCode
            uniqCode = title
        if uniqCode
            if codes[uniqCode]
                throw 'code is not uniq: ' + title
            codes[uniqCode] = true
        if filterByCode and filterByCode isnt uniqCode
            return {
                run: ->
            }
        makeScope = (title) ->
            self =
                title: title
                n: 0
                l_started: 0
                l_ok: 0
                l_error: 0
                closed: false
                close: ->
                    if self.closed
                        self.error 'Double close'
                        testList.push self
                        return
                    self.closed = true
                    stat.bFinished++
                    testList.splice(testList.indexOf(self), 1)
                    onClose()
                    if self.l_error or (self.l_started isnt self.l_ok)
                        console.warn "UT #{title} has problem: #{self.l_ok} of #{self.l_started}"
                start: (count) ->
                    stat.started += count
                    self.l_started += count
                error: (msg) ->
                    stat.error++
                    self.l_error++
                    console.error self.n, title, msg or ''
                ok: (msg) ->
                    stat.ok++
                    self.l_ok++
                    console.log self.n, title, msg or ''
                check: (value, msg) ->
                    self.n++
                    if value
                        self.ok msg
                    else
                        self.error msg
                equal: (a, b, msg) ->
                    self.n++
                    msg = msg or ''
                    if a is b
                        self.ok msg
                    else
                        self.error "not equal: #{a} != #{b} / #{msg}"
            testList.push self
            self

        r =
            run: (fn) ->
                alight = buildAlight.makeInstance()
                stat.bStarted++;
                timeout = Timeout()
                scope = makeScope title
                try
                    fn scope, alight, timeout
                    i = 9999
                    while true
                        if not timeout.next()
                            break
                        i--
                        if i < 0
                            throw 'Infinity timeout'
                catch e
                    err = e
                    if e.stack
                        err = e.stack
                    else if e.description
                        err = e.description
                    scope.error()
                    console.error '!!', err
        r
