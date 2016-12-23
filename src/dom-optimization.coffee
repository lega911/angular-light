_optimizeLineElements = {TR: 1, TD: 1, LI: 1}

alight.utils.optmizeElement = (element, noRemove) ->
    if element.nodeType is 1
        noRemove = noRemove or not alight.option.domOptimizationRemoveEmpty
        if element.nodeName is 'PRE'
            noRemove = true
        e = element.firstChild
        if e and e.nodeType is 3 and not e.nodeValue.trim() and not noRemove
            f$.remove e
            e = element.firstChild
        prevLineElement = false
        while e
            next = e.nextSibling
            if prevLineElement and e.nodeType is 3 and not e.nodeValue.trim() and not noRemove
                f$.remove e
            else
                prevLineElement = e.nodeType is 1 and _optimizeLineElements[e.nodeName]
                alight.utils.optmizeElement e, noRemove
            e = next
        e = element.lastChild
        if e and e.nodeType is 3 and not e.nodeValue.trim() and not noRemove
            f$.remove e
    else if element.nodeType is 3
        text = element.data
        mark = alight.utils.pars_start_tag
        i = text.indexOf(mark)
        if i < 0
            return
        if text.slice(i+mark.length).indexOf(mark) < 0
            return
        prev = 't'  # t, v, d, f
        current =
            value: ''
        result = [current]
        data = alight.utils.parsText text
        for d in data
            if d.type is 'text'
                current.value += d.value
            else
                exp = d.list.join '|'
                wrapped = alight.utils.pars_start_tag + exp + alight.utils.pars_finish_tag
                lname = exp.match /^([^\w\d\s\$"'\(\u0410-\u044F\u0401\u0451]+)/
                if lname
                    # directive
                    if prev is 't' or prev is 'd'
                        current.value += wrapped
                    else
                        current =
                            value: wrapped
                        result.push current
                    prev = 'd'
                else if d.list.length is 1
                    if prev is 't' or prev is 'v'
                        current.value += wrapped
                    else
                        current =
                            value: wrapped
                        result.push current
                    prev = 'v'
                else
                    # + filter
                    if prev is 't'
                        current.value += wrapped
                    else
                        current =
                            value: wrapped
                        result.push current

        if result.length < 2
            return

        e = element
        e.data = result[0].value
        for d in result[1..]
            n = document.createTextNode d.value
            f$.after e, n
            e = n
    return
