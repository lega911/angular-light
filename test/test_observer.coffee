

Test('observer #0').run ($test, alight) ->
    if not alight.debug.useObserver
        $test.close()
        return
    $test.start 8

    scope0 =
        user:
            name: 'macos'
    scope1 =
        user:
            name: 'windows'

    observer = alight.observer.create()
    a0 = 0
    ob0 = observer.observe scope0
    ob0.watch 'user.name', ->
        a0++
    a1 = 0
    ob1 = observer.observe scope1
    ob1.watch 'user.name', ->
        a1++

    observer.deliver()
    $test.equal a0, 0
    $test.equal a1, 0

    scope0.user.name = 'linux'
    observer.deliver()
    $test.equal a0, 1
    $test.equal a1, 0

    scope1.user.name = 'freebsd'
    observer.deliver()
    $test.equal a0, 1
    $test.equal a1, 1

    scope0.user.name = 'a'
    scope1.user.name = 'b'
    observer.deliver()
    $test.equal a0, 2
    $test.equal a1, 2

    $test.close()


Test('observer #1').run ($test, alight) ->
    if not alight.debug.useObserver
        $test.close()
        return
    $test.start 27

    scope =
        user:
            name: 'macos'

    observer = alight.observer.create()

    wroot = 0
    ob = observer.observe scope
    ob.rootEvent = ->
        wroot++

    wuser = 0
    wrole = 0
    w0 = ob.watch 'user.name', ->
        wuser++
    w1 = ob.watch 'user.acl.role', ->
        wrole++

    #alight.observer.unwatch wtree, 'user.name', w1
    glob = {}

    steps = [
        (next) ->
            scope.title = 'test'
            observer.deliver()
            $test.equal wroot, 1
            $test.equal wuser, 0, 'wuser 0'
            $test.equal wrole, 0
        (next) ->
            scope.user.name = 'linux'
            observer.deliver()
            $test.equal wroot, 1
            $test.equal wuser, 1, 'wuser 1'
            $test.equal wrole, 0
        (next) ->
            scope.base = {}
            observer.deliver()
            $test.equal wroot, 2
            $test.equal wuser, 1
            $test.equal wrole, 0
        (next) ->
            scope.base.title = 'base'
            observer.deliver()
            $test.equal wroot, 2
            $test.equal wuser, 1
            $test.equal wrole, 0
        (next) ->
            scope.user.acl =
                role: 'default'
            observer.deliver()
            $test.equal wroot, 2
            $test.equal wuser, 1
            $test.equal wrole, 1
        (next) ->
            glob.oldAcl = scope.user.acl
            scope.user =
                name: 'linux'
                acl:
                    role: 'base'
            observer.deliver()
            $test.equal wroot, 3
            $test.equal wuser, 2
            $test.equal wrole, 2
        (next) ->
            scope.user.acl.role = 'admin'
            observer.deliver()
            $test.equal wroot, 3
            $test.equal wuser, 2
            $test.equal wrole, 3
        (next) ->
            glob.oldAcl.role = 'Old role'
            observer.deliver()
            $test.equal wroot, 3
            $test.equal wuser, 2
            $test.equal wrole, 3
        (next) ->
            ob.destroy()
            scope.base = {}
            scope.user.name = 'new value'
            scope.user.acl.role = 'new value'
            observer.deliver()
            $test.equal wroot, 3
            $test.equal wuser, 2
            $test.equal wrole, 3
            
            $test.close()
    ]

    for fn in steps
        fn()
    null


Test('observer array#0').run ($test, alight) ->
    if not alight.debug.useObserver
        $test.close()
        return
    $test.start 4

    scope =
        list: [
            user:
                name: 'macos'
        ]

    observer = alight.observer.create()
    ob = observer.observe scope

    wlist = 0
    w0 = ob.watch 'list', ->
        wlist++

    observer.deliver()
    $test.equal wlist, 0

    scope.list.push
        user:
            name: 'ubuntu'

    observer.deliver()
    $test.equal wlist>0, true
    wlist = 0

    scope.list[0].user.name = 'linux'
    observer.deliver()
    $test.equal wlist, 0

    $test.equal !scope.list[0].$$observer, true
    $test.close()


Test('observer array#1').run ($test, alight) ->
    if not alight.debug.useObserver
        $test.close()
        return
    $test.start 4

    scope =
        data:
            list: [
                user:
                    name: 'macos'
            ]

    observer = alight.observer.create()
    ob = observer.observe scope

    wlist = 0
    w0 = ob.watch 'data.list', ->
        wlist++

    observer.deliver()
    $test.equal wlist, 0

    scope.data.list.push
        user:
            name: 'ubuntu'

    observer.deliver()
    $test.equal wlist>0, true
    wlist = 0

    scope.data.list[0].user.name = 'linux'
    observer.deliver()
    $test.equal wlist, 0

    $test.equal !scope.data.list[0].$$observer, true
    $test.close()


Test('observer-scope array#0').run ($test, alight) ->
    if not alight.debug.useObserver
        $test.close()
        return
    $test.start 17

    scope = alight.Scope()
    scope.data =
        list: [
            user:
                name: 'linux'
        ]
    scope.ar = []

    acount = 0
    scope.$watch 'data.list', ->
        acount++
    ,  
        isArray: true

    acount2 = 0
    scope.$watch 'ar', ->
        acount2++
    ,  
        isArray: true

    acount3 = 0
    scope.$watch 'data.list.length', ->
        acount3++    

    acount4 = 0
    scope.$watch 'ar.length', ->
        acount4++    

    scope.$scan ->
        $test.equal acount, 1
        $test.equal acount2, 1
        $test.equal acount3, 0
        $test.equal acount4, 0

        $test.equal not scope.data.list[0].$$observer, true

        scope.data.list.push
            user:
                name: 'macos'
        scope.ar.push 1

        scope.$scan ->
            $test.equal acount, 2
            $test.equal acount2, 2

            $test.equal acount3, 1
            $test.equal acount4, 1

            scope.$scan ->
                $test.equal acount, 2
                $test.equal acount2, 2
                $test.equal acount3, 1
                $test.equal acount4, 1

                scope.data.list = []
                scope.ar = []
                scope.$scan ->
                    $test.equal acount, 3
                    $test.equal acount2, 3
                    $test.equal acount3, 2
                    $test.equal acount4, 2

    scope.$destroy()
    $test.close()


Test('observer Scope').run ($test, alight) ->
    $test.start 26

    scope = alight.Scope()
    scope.a = ''
    scope.b = ''

    userName = 0
    userRole = 0
    wsum = ''
    wcount = 0
    scope.$watch 'user.name', (value) ->
        userName++
    scope.$watch 'user.acl.role', (value) ->
        userRole++
    scope.$watch 'a + "_" + b', (value) ->
        wsum = value
        wcount++

    scope.$scan ->
        $test.equal userName, 0
        $test.equal userRole, 0
        $test.equal wcount, 0
        $test.equal wsum, ''

        scope.user =
            name: 'demo'
        scope.a = 'one'

        scope.$scan ->
            $test.equal userName, 1
            $test.equal userRole, 0
            $test.equal wcount, 1
            $test.equal wsum, 'one_'

            scope.user.name = 'linux'
            scope.b = 'two'

            scope.$scan ->
                $test.equal userName, 2
                $test.equal userRole, 0
                $test.equal wcount, 2
                $test.equal wsum, 'one_two'

                scope.user =
                    name: 'linux'
                    acl:
                        role: 'basic'
                scope.a = 'linux'
                scope.b = 'ubuntu'

                scope.$scan ->
                    $test.equal userName, 2
                    $test.equal userRole, 1
                    $test.equal wcount, 3
                    $test.equal wsum, 'linux_ubuntu'

                    scope.user.acl.role = 'admin'

                    scope.$scan ->
                        $test.equal userName, 2
                        $test.equal userRole, 2
                        $test.equal wcount, 3
                        $test.equal wsum, 'linux_ubuntu'

                        oldAcl = scope.user.acl
                        scope.user =
                            name: 'freebsd'
                            acl:
                                role: 'root'

                        scope.$scan ->
                            $test.equal userName, 3
                            $test.equal userRole, 3

                            oldAcl.role = 'old role'

                            scope.$scan ->
                                $test.equal userName, 3
                                $test.equal userRole, 3

                                scope.$destroy()
                                scope.user.name = 'new value'
                                scope.user.acl.role = 'new value'

                                scope.$scan ->
                                    $test.equal userName, 3
                                    $test.equal userRole, 3
                                    $test.close()


Test('observer Scope#2').run ($test, alight) ->
    # watch for parent model
    $test.start 8

    s0 = alight.Scope()
    s1 = s0.$new()

    s0.var1 = ''
    s0.path =
        var2: ''

    count1 = 0
    value1 = ''
    s1.$watch 'var1', (v) ->
        count1++
        value1 = v

    count2 = 0
    value2 = ''
    s1.$watch 'path.var2', (v) ->
        count2++
        value2 = v

    s1.$scan ->
        s0.var1 = 'linux'
        s0.path.var2 = 'ubuntu'

        s1.$scan ->
            $test.equal count1, 1
            $test.equal value1, 'linux'
            $test.equal count2, 1
            $test.equal value2, 'ubuntu'

            s0.path =
                var2: 'redhat'
            s0.$scan ->
                $test.equal count2, 2
                $test.equal value2, 'redhat'

                s0.$destroy()
                s0.var1 = 'new'
                s0.path.var2 = 'new'

                s0.$scan ->
                    $test.equal count2, 2
                    $test.equal value2, 'redhat'
                    $test.close()


Test('observer Scope #3').run ($test, alight) ->
    $test.start 1

    s0 = alight.Scope()
    s0.path =
        var: 1
    s1 = s0.$new()
    #s2 = s1.$new()

    value = null
    s1.$watch 'path.var', (v) ->
        value = v

    s0.path.var = 3
    s1.$scan ->
        $test.equal value, 3

        $test.close()



Test('observer watchText#0').run ($test, alight) ->
    $test.start 9

    scope = alight.Scope()
    scope.os =
        kind: 'linux'
        name: 'Ubuntu'

    result = ''
    count = 0
    w = scope.$watchText 'OS: {{os.kind}} {{os.name}}', (value) ->
        count++
        result = value

    $test.equal w.value, 'OS: linux Ubuntu'

    scope.$scan ->
        $test.equal count, 0
        $test.equal result, ''

        scope.os.name = 'Debian'

        scope.$scan ->
            $test.equal count, 1
            $test.equal result, 'OS: linux Debian'

            scope.os =
                kind: 'MacOS'
                name: 'X'

            scope.$scan ->
                $test.equal count, 2
                $test.equal result, 'OS: MacOS X'

                scope.$scan ->
                    $test.equal count, 2
                    $test.equal result, 'OS: MacOS X'
                    $test.close()
