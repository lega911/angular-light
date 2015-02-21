
stat =
	started: 0
	ok: 0
	error: 0

window.Test = Test = (title) ->
	n = 0
	self =
		start: (n) ->
			stat.started += n
		error: (msg) ->
			stat.error++
			console.error n, title, msg or ''
		ok: (msg) ->
			stat.ok++
			console.log n, title, msg or ''
		check: (value, msg) ->
			n++
			if value
				self.ok msg
			else
				self.error msg
		equal: (a, b, msg) ->
			n++
			msg = msg or ''
			if a is b
				self.ok msg
			else
				self.error "not equal: #{a} != #{b} / #{msg}"
		run: (fn) ->
			alight = buildAlight()
			try
			  fn self, alight
			catch e
				err = if typeof(e) is 'string' then e else e.stack
				self.error()
				console.error err
			if not Object.observe
				return
			alight = buildAlight()
			alight.debug.useObserver = true
			try
			  fn self, alight
			catch e
				err = if typeof(e) is 'string' then e else e.stack
				self.error()
				console.error err

		totals: ->
			msg = "Started #{stat.started}, Ok #{stat.ok}, Error #{stat.error}"
			if stat.error or stat.started isnt stat.ok
				console.error msg
			else
				console.log msg
			stat

# show totals
setTimeout ->
	if stat.started is stat.ok
		Test().totals()
	else
		setTimeout ->
			console.error 'timeout 4 sec'
			Test().totals()
		, 4000
, 2000
