	/* prev prefix.js */
		return alight;
	}; // finish of buildAlight

	var alight = buildAlight();
	alight.makeInstance = buildAlight;

	if(typeof(alightInitCallback) === 'function') {
		alightInitCallback(alight)
	} else if(typeof(define) === 'function') {  // requrejs/commonjs
		define(function() {
			return alight;
		});
	} else if(typeof(module) === 'object' && typeof(module.exports) === 'object') {
		module.exports = alight
	} else {
		alight.option.globalController = true;  // global controllers
		window.alight = alight;
		alight.f$.ready(alight.bootstrap);
	};
})();
