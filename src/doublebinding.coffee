
alight.core.DoubleBinding = ->
    doubles = []
    timeout = null
    active = []

    displayLog = ->
        index = timeout
        timeout = null
        for d in doubles
            d.node.index = index
            if d.element.parentNode
                parentNode = getNode d.element.parentNode
                if parentNode.index is index
                    continue
            text = d.parentDir + ' -> '
            for dir, count of d.node.started
                if count > 1
                    text += ' ' + dir
            element = d.element
            if element.nodeType is 3
                element = element.parentNode
            console.warn text, element
        doubles.length = 0
        return

    getNode = (element) ->
        node = element.__dbiner
        if node
            return node
        node =
            started: {}
            count: 0
            binder: []
        element.__dbiner = node
        node

    startDirective: (element, dirName, value, isText) ->
        node = getNode element
        if node.started[dirName]
            node.started[dirName] += 1
            doubles.push
                element: element
                parentDir: active[active.length-1] or 'Manual'
                node: node
            if not timeout
                timeout = setTimeout displayLog, 100
        else
            node.started[dirName] = 1
        if not isText
            active.push "#{dirName}=\"#{value}\""

    finishDirective: (element, dirName) ->
        node = getNode element
        active.pop()
