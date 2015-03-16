
Test('parsExpression').run ($test, alight) ->
    pars = (line, expected, cfg) ->
        $test.start 1
        result = alight.utilits.parsExpression line, cfg
        ok = true
        if result.length is expected.length
            for i in [0..result.length-1] by 1
                if result[i] isnt expected[i]
                    ok = false
        else
            ok = false

        $test.check ok, result
    # ($$=$$scope.a,$$==null)?undefined:($$=$$.b,$$==null)?undefined:$$.c
    pars 'path.variable', ["(($$=$$scope.path,$$==null)?undefined:$$.variable)"]
    pars 'aaa.bbb.ccc.fn()', ["(($$=$$scope.aaa,$$==null)?undefined:($$=$$.bbb,$$==null)?undefined:$$.ccc).fn()"]
    pars 'aaa.bbb.fn()', ["(($$=$$scope.aaa,$$==null)?undefined:$$.bbb).fn()"]
    pars 'aaa.fn()', ["$$scope.aaa.fn()"]
    pars 'fn()', ["$$scope.fn()"]
    pars 'variable', ["$$scope.variable"]
    pars 'a + b.c + d.e.f', ["$$scope.a + (($$=$$scope.b,$$==null)?undefined:$$.c) + (($$=$$scope.d,$$==null)?undefined:($$=$$.e,$$==null)?undefined:$$.f)"]
    pars 'foo.baz=one.two.three', ["$$scope.foo.baz=(($$=$$scope.one,$$==null)?undefined:($$=$$.two,$$==null)?undefined:$$.three)"]
    pars 'foo.baz==one.two.three', ["(($$=$$scope.foo,$$==null)?undefined:$$.baz)==(($$=$$scope.one,$$==null)?undefined:($$=$$.two,$$==null)?undefined:$$.three)"]
    pars 'a=5; b=6;', ["$$scope.a=5; $$scope.b=6;"]
    pars 'do(item)', ["$$scope.do($$scope.item)"]
    pars "a+'/'+b", ["$$scope.a+'/'+$$scope.b"]
    pars 'page==5', ["$$scope.page==5"]
    pars "path.var | toref | filter 'ref|str' ", ["(($$=$$scope.path,$$==null)?undefined:$$.var) ", " toref ", " filter 'ref|str' "]
    pars " (function(){ return '|' })() | toref | filter", [" (function(){ return '|' })() ", " toref ", " filter"]
    pars " (a || b) ", [" ($$scope.a || $$scope.b) "]
    pars " (a | b) | filter ", [" ($$scope.a | $$scope.b) ", " filter "]
    pars " { red:true, blue:false }[color] ", [" { red:true, blue:false }[$$scope.color] "]
    pars "x + function(){ return num + 5 }()", ['$$scope.x + function(){ return $$scope.num + 5 }()']
    pars "this.title='linux'; click()", ["$$scope.title='linux'; $$scope.click()"]
    pars "[1,2,3,4,5,6,7,8,9]", ["[1,2,3,4,5,6,7,8,9]"]
    pars "$index===0", ["$$scope.$index===0"]
    pars "list[key].value", ['$$scope.list[$$scope.key].value']
    pars "list[key].value = test", ['$$scope.list[$$scope.key].value = test'], { input:['test'] }
    pars '((obj || {}).ext || {}).visible', ['(($$scope.obj || {}).ext || {}).visible']
    pars 'a || b | filter', ['$$scope.a || $$scope.b ', ' filter']
    pars "value = $event.keyCode", ['$$scope.value = $event.keyCode'], { input:['$event'] }
    pars "'('+a+')'", ["'('+$$scope.a+')'"]
    pars "{ key:value, key2:value2 }", ["{ key:$$scope.value, key2:$$scope.value2 }"]
    pars 'a.b.c.d.e.f.g', ["(($$=$$scope.a,$$==null)?undefined:($$=$$.b,$$==null)?undefined:($$=$$.c,$$==null)?undefined:($$=$$.d,$$==null)?undefined:($$=$$.e,$$==null)?undefined:($$=$$.f,$$==null)?undefined:$$.g)"]
    pars "scope=this", ["$$scope.scope=$$scope"]
    pars "info.user.acl('write', 're_type:546a1d07bb05aa73a632807d')", ["(($$=$$scope.info,$$==null)?undefined:$$.user).acl('write', 're_type:546a1d07bb05aa73a632807d')"]
    cyWord = "\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0430\u041a\u0438\u0440\u0438\u043b\u0438\u0446\u044b\u0401\u0451\u0419\u0439"
    pars "Form.#{cyWord}", ["(($$=$$scope.Form,$$==null)?undefined:$$.#{cyWord})"]
    #pars '=obj.items.short_name || obj.name', []

    $test.close()


Test('parsText').run ($test, alight) ->
    $test.start 5

    r = alight.utilits.parsText '  {{a}} {{b}}  '
    $test.check r[0].value is '  ' and r[1].list[0] is 'a' and r[2].value is ' ' and r[3].list[0] is 'b' and r[4].value is '  '

    r = alight.utilits.parsText '  {{a}}{{b}}  '
    $test.check r[0].value is '  ' and r[1].list[0] is 'a' and r[2].list[0] is 'b' and r[3].value is '  '

    r = alight.utilits.parsText '{{a}}{{b}}'
    $test.check r[0].list[0] is 'a' and r[1].list[0] is 'b'

    r = alight.utilits.parsText "label {{#get tag.ref -> items.css, $value || 'label-default'}}"
    $test.equal r[0].value, 'label '
    $test.equal r[1].list[0], "#get tag.ref -> items.css, $value || 'label-default'"

    $test.close()
