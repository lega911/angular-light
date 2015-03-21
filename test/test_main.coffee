
stat =
	started: 0
	ok: 0
	error: 0
	bStarted: 0
	bFinished: 0

testList = []


printTotals = ->
	msg = "Started #{stat.started}, Ok #{stat.ok}, Error #{stat.error}"
	if stat.error or stat.started isnt stat.ok
		console.error msg
	else
		console.log msg
	stat


to = setTimeout ->
	console.error 'timeout 4 sec'
	printTotals()
	for t in testList
		console.error 'opened UT:', t.title
, 4000


onClose = ->
	if stat.bStarted isnt stat.bFinished
		return
	printTotals()
	clearTimeout to


do ->
	stat.bStarted++;
	$ ->
		stat.bFinished++;
		onClose()


window.Test = do ->
	codes = {}
	filterByCode = document.location.hash[1..]
	(title, uniqCode) ->
		if uniqCode
			if codes[uniqCode]
				throw 'code is not uniq: ' + title
			codes[uniqCode] = true
		if filterByCode and filterByCode isnt uniqCode
			return {
				run: ->
			}
		makeScope = (title) ->
			self =
				title: title
				n: 0
				l_started: 0
				l_ok: 0
				l_error: 0
				closed: false
				close: ->
					if self.closed
						self.error 'Double close'
						testList.push self
						return
					self.closed = true
					stat.bFinished++
					testList.splice(testList.indexOf(self), 1)
					onClose()
					if self.l_error or (self.l_started isnt self.l_ok)
						console.warn "UT #{title} has problem: #{self.l_ok} of #{self.l_started}"
				start: (count) ->
					stat.started += count
					self.l_started += count
				error: (msg) ->
					stat.error++
					self.l_error++
					console.error self.n, title, msg or ''
				ok: (msg) ->
					stat.ok++
					self.l_ok++
					console.log self.n, title, msg or ''
				check: (value, msg) ->
					self.n++
					if value
						self.ok msg
					else
						self.error msg
				equal: (a, b, msg) ->
					self.n++
					msg = msg or ''
					if a is b
						self.ok msg
					else
						self.error "not equal: #{a} != #{b} / #{msg}"
			testList.push self
			self

		r =
			run: (fn) ->
				alight = buildAlight()
				stat.bStarted++;
				scope = makeScope title
				try
					fn scope, alight
				catch e
					err = e
					if e.stack
						err = e.stack
					else if e.description
						err = e.description
					scope.error()
					console.error '!!', err

				# test with observer
				if not Object.observe
					return
				alight = buildAlight()
				alight.debug.useObserver = true
				stat.bStarted++;
				scope = makeScope "ob+#{title}"
				try
					fn scope, alight
				catch e
					err = e
					if e.stack
						err = e.stack
					else if e.description
						err = e.description
					scope.error()
					console.error '!!', err
		r
