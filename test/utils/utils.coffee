
Test('utils.equal').run ($test, alight) ->
	$test.start 8

	u = alight.utils
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
	b.obj.date = new Date(2015, 1, 1)
	$test.check not u.equal a, b
	$test.close()
