
###
    FF:
        fill 152.4
        scan 253.0
        destroy 9.2
        destroy partial 22.9

    Chrome:
        fill 191.8
        scan 520.6
        destroy 10.4
        destroy partial 28.7

###

###
    0.11.5b
    FF:
        fill 117.8
        scan 256.7
        destroy 5.1
        destroy partial 10.4

    Chrome:
        fill 154.3
        scan 377.0
        destroy 3.6
        destroy partial 3.9

    0.12.2b Chrome
        fill 46.7
        scan 391.9
        destroy 3.6
        destroy partial 4.5
        watch array 344.7

    0.12.3b Chrome
        fill 33.4
        scan 420.9
        destroy 3.3
        destroy partial 3.8
        watch array 344.5

###

fillCD = (count) ->

    empty = ->
    root = alight.ChangeDetector()

    for i in [0..count]
        child = root.new {}
        for j in [0..count]
            child.scope['a'+j] = {b:{c:1}}
            child.watch 'a'+j+'.b.c', empty

    root


print = (text) ->
    p = document.createElement 'p'
    p.innerText = text
    document.body.appendChild p


timeit = (name, count, fn) ->
    start = performance.now()
    while count
        count--
        fn()
    duration = performance.now() - start
    print "#{name} #{duration.toFixed(1)}"


runCreating = ->
    timeit 'fill', 1, ->
        fillCD 100


runScanning = ->
    # 100x100 watches x 1000 loops = 10M checks
    root = fillCD 100
    timeit 'scan', 1000, ->
        root.scan()


runDestroy = ->
    list = []
    for i in [0..10]
        root = fillCD 100
        for cd, i in root.children
            if i%2
                list.push cd

    timeit 'destroy', 1, ->
        for cd in list
            cd.destroy()
        null


runDestroyPartial = ->
    list = for i in [0..10]
        fillCD 100

    timeit 'destroy partial', 1, ->
        for cd in list
            cd.destroy()
        null


runWatchArray = ->
    list = for i in [0..10000]
        {}
    cd = alight.ChangeDetector
        list: list
    cd.watch 'list', ->
        null
    ,
        isArray: true
    timeit 'watch array', 10000, ->
        cd.scan()
        null


run = ->
    print alight.version
    line = [
        runCreating,
        runScanning,
        runDestroy,
        runDestroyPartial,
        runWatchArray
    ]

    n = Number location.hash.substring 1
    if n and typeof n is 'number'
        setTimeout ->
            line[n]()
        , 2000
    else
        n = 0
        step = ->
            fn = line[n++]
            if not fn
                return
            fn()
            setTimeout step, 1000

        setTimeout step, 1000

alight.f$.ready run
