
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

fillCD = (count) ->

    empty = ->
    root = alight.ChangeDetector()

    for i in [0..count]
        child = root.new {}
        for j in [0..count]
            child.scope['a'+j] = {b:{c:1}}
            child.watch 'a'+j+'.b.c', empty

    root


timeit = (name, count, fn) ->
    start = performance.now()
    while count
        count--
        fn()
    duration = performance.now() - start
    #console.log name, duration
    p = document.createElement 'p'
    p.innerHTML = "#{name} #{duration.toFixed(1)}"
    document.body.appendChild p


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


run = ->
    line = [
        runCreating,
        runScanning,
        runDestroy,
        runDestroyPartial
    ]

    n = 0
    step = ->
        fn = line[n++]
        if not fn
            return
        fn()
        setTimeout step, 1000

    setTimeout step, 1000

run()
