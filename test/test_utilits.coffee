
Test('utilits.equal').run ($test, alight) ->
	$test.start 8

	u = alight.utilits
	a =
		num: 1
		str: 'two'
		obj:
			date: new Date()
			list: [1, 2, 3]

	b = u.clone a

	$test.check u.equal a, b
	
	b.num++
	$test.check not u.equal a, b

	b = u.clone a
	b.str = 'three'
	$test.check not u.equal a, b

	b = u.clone a
	b.attr = null
	$test.check not u.equal a, b
	$test.check not u.equal b, a

	b = u.clone a
	b.obj.attr = true
	$test.check not u.equal a, b

	b = u.clone a
	b.obj.list.push 7
	$test.check not u.equal a, b

	b = u.clone a
	b.obj.date = new Date()
	$test.check not u.equal a, b


Test('$compile + filter').run ($test, alight) ->
	$test.start 2

	alight.filters.test0 = (exp, scope) ->
		(value) ->
			value + ':' + scope.name

	s0 = alight.Scope()
	s1 = alight.Scope()

	s0.name = 'debian'
	s1.name = 'ubuntu'

	f0 = s0.$compile 'name | test0'
	f1 = s1.$compile 'name | test0'

	$test.equal f0(), 'debian:debian'
	$test.equal f1(), 'ubuntu:ubuntu'
