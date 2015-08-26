
alight.utils.pars_start_tag = '{{'
alight.utils.pars_finish_tag = '}}'

rawParsText = (line) ->
    start_tag = alight.utils.pars_start_tag
    finish_tag = alight.utils.pars_finish_tag
    result = []
    index = 0
    prev_index = 0

    get_part = (count)->
        count = count or 1
        r = line.substring prev_index, index - count
        prev_index = index
        r

    rexp = null
    pars = (lvl, stop, force) ->

        if not lvl
            rexp =
                type: 'expression'
                list: []
            result.push rexp

        prev = null
        a = null
        while index < line.length
            prev = a
            a = line[index]
            index += 1
            a2 = prev + a
            an = line[index]

            if a is stop
                return
            if force
                continue

            if a2 is finish_tag and lvl is 0
                rexp.list.push get_part(2)
                return true

            if a is '('
                pars lvl+1, ')'
            else if a is '{'
                pars lvl+1, '}'
            else if a is '"'
                pars lvl+1, '"', true
            else if a is "'"
                pars lvl+1, "'", true
            else if a is '|'
                if lvl is 0
                    if an is '|'  # operator ||
                        index += 1
                    else
                        rexp.list.push get_part()

    find_exp = () ->
        prev = null
        a = null
        while index < line.length
            prev = a
            a = line[index]
            index += 1
            a2 = prev + a

            if a2 is start_tag
                text = get_part(2)
                if text
                    result.push
                        type: 'text'
                        value: text
                if not pars 0
                    throw 'Wrong expression' + line
                a = null
        r = get_part(-1)
        if r
            result.push { type:'text', value:r }

    find_exp()
    if alight.debug.parser
        console.log 'parsText', result
    result


cache = {}

clone = (result) ->
    resp = for i in result
        k =
            type: i.type
            value: i.value
        if i.list
            k.list = i.list.slice()
        k
    return resp

alight.utils.parsText = (line) ->
    result = cache[line]
    if not result
        cache[line] = result = rawParsText line
    return clone result
