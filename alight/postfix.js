	/* prev prefix.js */
	if(typeof(alightInitCallback) === 'function') {
		alight.autostart = false;
		alightInitCallback(alight)
	} else {
		window.alight = alight;
		window.f$ = f$;
		enableGlobalControllers = true;
	};
	f$.ready(function() {
		if(alight.autostart) alight.bootstrap()
	})
})();
