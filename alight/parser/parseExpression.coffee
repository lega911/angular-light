
# http://es5.github.io/#A.1
#reserved = ['break', 'do', 'instanceof', 'typeof', 'case', 'else', 'new', 'var', 'catch', 'finally', 'return', 'void', 'continue', 'for', 'switch', 'while', 'debugger', 'function', 'this', 'with', 'default', 'if', 'throw', 'delete', 'in', 'try', 'class', 'enum', 'extends', 'super', 'const', 'export', 'import', 'null', 'true', 'false', 'undefined']
reserved =
    'instanceof': true
    'typeof': true
    'in': true
    'null': true
    'true': true
    'false': true
    'undefined': true
    'function': true
    'return': true

alight.utils.parsExpression = (line, cfg) ->
    cfg = cfg or {}
    input = cfg.input or []
    index = 0
    result = []
    prev = 0
    variables = []
    variable_names = []
    variable_assignment = []
    variable_fn = []
    simpleVariables = []
    isSimple = not input.length
    pars = (lvl, stop, convert, is_string) ->
        variable = ''
        variable_index = -1
        var_before = false

        check_variabe = ->
            if not variable
                return
            if reserved[variable]
                return
            var_main = variable.split('.')[0]
            if input.indexOf(var_main) >= 0
                return
            if variable[0].match /[\d\.]/
                return
            variables.push variable_index
            variable_names.push variable
            variable_assignment.push false
            variable_fn.push false
            true

        while index < line.length
            ap = line[index-1]
            a = line[index]
            index += 1
            an = line[index]  # next

            if convert
                #if a.match /[\d\wа-яА-ЯёЁ_\.\$]/
                if a.match /[\d\w\u0410-\u044F\u0401\u0451_\.\$]/
                    if not variable
                        variable_index = index - 1
                    variable += a
                else
                    if stop is '}'  # is dict?
                        if line.substring(index-1).trim()[0] is ':'
                            variable = ''
                    if check_variabe()
                        var_before = index
                    variable = ''

            if a is stop
                return

            if var_before
                if a isnt ' ' and var_before isnt index
                    var_before = false

            if a is '='
                if ap isnt '=' and an isnt '=' # assignment in prev variable
                    variable_assignment[variable_assignment.length-1] = true

            if a is '+'
                if an is '+' or an is '='
                    variable_assignment[variable_assignment.length-1] = true

            if a is '-'
                if an is '-' or an is '='
                    variable_assignment[variable_assignment.length-1] = true

            if a is '(' and not is_string
                if var_before
                    variable_fn[variable_fn.length-1] = true  # it's function
                pars lvl+1, ')', convert
            else if a is '[' and not is_string
                pars lvl+1, ']', convert
            else if a is '{' and not is_string
                pars lvl+1, '}', true
            else if a is '"'
                pars lvl+1, '"', false, true
            else if a is "'"
                pars lvl+1, "'", false, true
            else if a is '|'
                if lvl is 0
                    if an is '|'  # operator ||
                        index += 1
                    else
                        convert = false
                        result.push line.substring prev, index-1
                        prev = index
        if lvl is 0
            result.push line.substring prev
        check_variabe()

    pars(0, null, true)
    expression = result[0]
    if variables.length
        exp = result[0]
        for n, i in variables by -1
            # convert variables
            # a -> $$scope.a
            # a.b -> (($$=$$scope.a,$$==null)?undefined:$$.b)
            # a.b.c -> (($$=$$scope.a,$$==null)?undefined:($$=$$.b,$$==null)?undefined:$$.c)
            variable = variable_names[i]
            assignment = variable_assignment[i]
            is_function = variable_fn[i]

            if not is_function and not assignment
                simpleVariables.push variable
            if is_function or assignment
                isSimple = false

            d = variable.split '.'
            conv = false
            if d.length > 1 and not assignment
                if is_function
                    conv = d.length > 2
                else
                    conv = true
            if conv
                newName = null
                if d[0] is 'this'
                    d[0] = '$$scope'
                    if d.length is 2
                        newName = '$$scope.' + d[1]
                if not newName
                    l = []
                    l.push "($$=$$scope.#{d[0]},$$==null)?undefined:"
                    if is_function
                        for i in d[1..d.length-3]
                            l.push "($$=$$.#{i},$$==null)?undefined:"
                        l.push "$$.#{d[d.length-2]}"
                        newName = '(' + l.join('') + ').' + d[d.length-1]
                    else
                        for i in d[1..d.length-2]
                            l.push "($$=$$.#{i},$$==null)?undefined:"
                        l.push "$$.#{d[d.length-1]}"
                        newName = '(' + l.join('') + ')'
            else
                if variable is 'this'
                    newName = '$$scope'
                else if d[0] is 'this'
                    newName = '$$scope.' + d[1..].join '.'
                else
                    newName = '$$scope.' + variable
            exp = exp.slice(0, n) + newName + exp.slice(n + variable.length)
        result[0] = exp
    if alight.debug.parser
        console.log 'parser', result

    hasFilters = result.length > 1
    if hasFilters
        isSimple = false

    result: result
    expression: expression
    simpleVariables: simpleVariables
    isSimple: isSimple
    hasFilters: hasFilters
