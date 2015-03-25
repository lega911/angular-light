
Test('$watch function/$any').run ($test, alight) ->
	$test.start 26

	col0 = 0
	col1 = 0
	col2 = 0
	col3 = 0
	col4 = 0
	A = 5

	scope = alight.Scope()
	scope.x = 5
	scope.y = 7

	childScope = scope.$new()

	scope.$watch 'x', ->
		col0++

	childScope.$watch '$any', ->
		col1++

	scope.$watch ->
		col3++
		A
	, ->
		col2++

	scope.$watch 'y', ->
		col4++
	, { readOnly:true }

	$test.equal col3, 1

	scope.$scan ->
		$test.equal col0, 0, '/1'
		$test.equal col1, 0
		$test.equal col2, 0
		$test.equal col3, 2
		$test.equal col4, 0

		scope.x = 7

		scope.$scan ->
			$test.equal col0, 1, '/2'
			$test.equal col1, 1
			$test.equal col2, 0
			$test.equal col3, 4  # +1 loop
			$test.equal col4, 0

			A = 7

			scope.$scan ->
				$test.equal col0, 1, '/3'
				$test.equal col1, 2
				$test.equal col2, 1
				$test.equal col3, 6  # +1 loop
				$test.equal col4, 0

				scope.$scan ->
					$test.equal col0, 1, '/4'
					$test.equal col1, 2
					$test.equal col2, 1
					$test.equal col3, 7
					$test.equal col4, 0

					scope.y = 3

					scope.$scan ->
						$test.equal col0, 1, '/5'
						$test.equal col1, 3
						$test.equal col2, 1
						$test.equal col3, 8
						$test.equal col4, 1
						$test.close()

Test('$scan root #0', 'scan-root-0').run ($test, alight) ->
	$test.start 15

	c0 = 0
	c1 = 0
	c2 = 0

	s0 = alight.Scope()
	s1 = s0.$new()
	s2 = s1.$new()

	s0.$watch 'dict.x', ->
		c0++
	s1.$watch 'dict.x', ->
		c1++
	s2.$watch 'dict.x', ->
		c2++

	s0.dict = dict =
		x: 0

	s1.$scan ->
		$test.equal c0, 1, '/1'
		$test.equal c1, 1
		$test.equal c2, 1

		dict.x++

		s1.$scan ->
			$test.equal c0, 2, '/2'
			$test.equal c1, 2
			$test.equal c2, 2

			dict.x++

			s1.$scan ->
				$test.equal c0, 3, '/3'
				$test.equal c1, 3
				$test.equal c2, 3

				dict.x++

				s1.$scan ->
					$test.check c0 is 4, '/4'
					$test.check c1 is 4
					$test.check c2 is 4

					s1.$scanAsync ->
						$test.check c0 is 4, '/5'
						$test.check c1 is 4
						$test.check c2 is 4
						$test.close()

Test('$scan late').run ($test, alight) ->
	$test.start 18

	c0 = 0
	c1 = 0
	c2 = 0

	scope = alight.Scope()
	scope.n = 0
	scope.$watch ->
		c0++
		null
	, ->
	scope.$watch 'n', ->
		c2++

	$test.equal c0, 1
	$test.equal c1, 0
	$test.equal c2, 0
	scope.$scan ->
		$test.equal c0, 2
		$test.equal c1, 0
		$test.equal c2, 0

		alight.nextTick ->
			$test.equal c0, 2
			$test.equal c1, 0
			$test.equal c2, 0

		scope.n++
		scope.$scan
			late: true
			callback: ->
				c1++

		setTimeout ->
			$test.equal c0, 4
			$test.equal c1, 1
			$test.equal c2, 1

			next()
		, 100

	next = ->
		scope.n++
		scope.$scanAsync ->
			c1++
			$test.equal c0, 6
			$test.equal c1, 2
			$test.equal c2, 2
			$test.close()

		$test.equal c0, 4
		$test.equal c1, 1
		$test.equal c2, 1


Test('$scan order').run ($test, alight) ->
	$test.start 7
	scope = alight.Scope()
	scope.v0 = 0
	scope.v1 = 0
	scope.v2 = 0

	v0 = 0
	v1 = 0
	v2 = 0
	scope.$watch 'v0', ->
		v0++
		$test.equal v1, 1
	scope.$watch 'v1', ->
		v1++
		scope.v0++
		scope.$scan()
	, { readOnly:true }
	scope.$watch 'v2', ->
		v2++

	scope.$scan ->
		$test.equal v0, 0
		$test.equal v1, 0
		$test.equal v2, 0

		scope.v1++
		scope.$scan ->
			$test.equal v0, 1
			$test.equal v1, 1
			$test.equal v2, 0
			$test.close()


Test('$scan.deep').run ($test, alight) ->
	$test.start 4
	s = alight.Scope()
	s.a =
		num: 1
		str: 'two'
		obj:
			date: new Date()
			list: [1, 2, 3]

	n = 0
	s.$watch 'a', ->
		n++
	, deep: true

	s.$scan ->
		$test.equal n, 0

		s.a.num++
		s.$scan ->
			$test.equal n, 1

			s.a.two = null

			s.$scan ->
				$test.equal n, 2

				s.a.obj.list.push null

				s.$scan ->
					$test.equal n, 3
					$test.close()
