
Test('watch-function-any', 'watch-function-any').run ($test, alight) ->
	$test.start 26

	col0 = 0
	col1 = 0
	col2 = 0
	col3 = 0
	col4 = 0
	A = 5

	scope =
		x: 5
		y: 7
	root = alight.ChangeDetector scope
	childScope = root.new()

	root.watch 'x', ->
		col0++

	childScope.watch '$any', ->
		col1++

	root.watch ->
		col3++
		A
	, ->
		col2++

	root.watch 'y', ->
		col4++
	,
		readOnly: true

	$test.equal col3, 0

	root.scan ->
		$test.equal col0, 1, '/1'
		$test.equal col1, 1
		$test.equal col2, 1
		$test.equal col3, 2
		$test.equal col4, 1

		scope.x = 7

		root.scan ->
			$test.equal col0, 2, '/2'
			$test.equal col1, 2
			$test.equal col2, 1
			$test.equal col3, 4  # +1 loop
			$test.equal col4, 1

			A = 7

			root.scan ->
				$test.equal col0, 2, '/3'
				$test.equal col1, 3
				$test.equal col2, 2
				$test.equal col3, 6  # +1 loop
				$test.equal col4, 1

				root.scan ->
					$test.equal col0, 2, '/4'
					$test.equal col1, 3
					$test.equal col2, 2
					$test.equal col3, 7
					$test.equal col4, 1

					scope.y = 3

					root.scan ->
						$test.equal col0, 2, '/5'
						$test.equal col1, 4
						$test.equal col2, 2
						$test.equal col3, 8
						$test.equal col4, 2
						$test.close()

Test('$scan root #0', 'scan-root-0').run ($test, alight) ->
	$test.start 15

	c0 = 0
	c1 = 0
	c2 = 0

	s0 = alight.ChangeDetector()
	s1 = s0.new()
	s2 = s1.new()

	s0.watch 'dict.x', ->
		c0++
	s1.watch 'dict.x', ->
		c1++
	s2.watch 'dict.x', ->
		c2++

	s0.scope.dict = dict =
		x: 0

	s1.scan ->
		$test.equal c0, 1, '/1'
		$test.equal c1, 1
		$test.equal c2, 1

		dict.x++

		s1.scan ->
			$test.equal c0, 2, '/2'
			$test.equal c1, 2
			$test.equal c2, 2

			dict.x++

			s1.scan ->
				$test.equal c0, 3, '/3'
				$test.equal c1, 3
				$test.equal c2, 3

				dict.x++

				s1.scan ->
					$test.check c0 is 4, '/4'
					$test.check c1 is 4
					$test.check c2 is 4

					s1.scan
						callback: ->
							$test.check c0 is 4, '/5'
							$test.check c1 is 4
							$test.check c2 is 4
							$test.close()
						late: true

Test('scan-late', 'scan-late').run ($test, alight) ->
	$test.start 18

	c0 = 0
	c1 = 0
	c2 = 0

	scope =
		n: 0
	root = alight.ChangeDetector scope
	root.watch ->
		c0++
		null
	, ->
	root.watch 'n', ->
		c2++

	$test.equal c0, 0, 'start'
	$test.equal c1, 0
	$test.equal c2, 0
	root.scan ->
		$test.equal c0, 2, '1st scan'
		$test.equal c1, 0
		$test.equal c2, 1

		alight.nextTick ->
			$test.equal c0, 2, 'next tick'
			$test.equal c1, 0
			$test.equal c2, 1

		scope.n++
		root.scan
			late: true
			callback: ->
				c1++

		setTimeout ->
			$test.equal c0, 4, 'timeout 100'
			$test.equal c1, 1
			$test.equal c2, 2

			next()
		, 100

	next = ->
		scope.n++
		root.scan
			callback: ->
				c1++
				$test.equal c0, 6, 'scan late'
				$test.equal c1, 2
				$test.equal c2, 3
				$test.close()
			late: true

		$test.equal c0, 4, 'next'
		$test.equal c1, 1
		$test.equal c2, 2


Test('scan-order', 'scan-order').run ($test, alight) ->
	$test.start 6
	scope =
		v0: 0
		v1: 0
		v2: 0
	cd = alight.ChangeDetector scope

	v0 = 0
	v1 = 0
	v2 = 0
	cd.watch 'v0', ->
		v0++
		#$test.equal v1, 0, '1st test'  # callback of v1 isn't called yet
	cd.watch 'v1', ->
		v1++
		scope.v0++  # make call v0 second time
		cd.scan()
	,
		readOnly: true
	cd.watch 'v2', ->
		v2++

	cd.scan ->
		$test.equal v0, 2
		$test.equal v1, 1
		$test.equal v2, 1

		scope.v1++
		cd.scan ->
			$test.equal v0, 3
			$test.equal v1, 2
			$test.equal v2, 1
			$test.close()


Test('scan-deep', 'scan-deep').run ($test, alight) ->
	$test.start 4
	s =
		a:
			num: 1
			str: 'two'
			obj:
				date: new Date()
				list: [1, 2, 3]
	cd = alight.ChangeDetector s

	n = 0
	cd.watch 'a', ->
		n++
	, deep: true

	cd.scan ->
		$test.equal n, 1

		s.a.num++
		cd.scan ->
			$test.equal n, 2

			s.a.two = null

			cd.scan ->
				$test.equal n, 3

				s.a.obj.list.push null

				cd.scan ->
					$test.equal n, 4
					$test.close()
